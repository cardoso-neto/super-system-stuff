import json
import os
import shutil
import socket
import stat
import subprocess
from collections.abc import Iterator
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Event, Thread
from uuid import UUID

import pytest

pytestmark = pytest.mark.integration
REPORTER = Path(__file__).resolve().parents[1] / "report.sh"
FINDING = Path(__file__).parent / "fixtures" / "finding.txt"


@dataclass
class Endpoint:
    url: str = ""
    status: int = 200
    requests: list[bytes] = field(default_factory=list)
    received: Event = field(default_factory=Event)
    release: Event = field(default_factory=Event)


@pytest.fixture
def endpoint() -> Iterator[Endpoint]:
    endpoint = Endpoint()
    endpoint.release.set()

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            length = int(self.headers["Content-Length"])
            endpoint.requests.append(self.rfile.read(length))
            endpoint.received.set()
            if not endpoint.release.wait(timeout=15):
                return
            self.send_response(endpoint.status)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def log_message(self, format: str, *args: object) -> None:
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    endpoint.url = (
        f"http://127.0.0.1:{server.server_port}"
        "/report/private-test-token?secret=private-query-token"
    )
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield endpoint
    finally:
        endpoint.release.set()
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


@dataclass
class Reporter:
    config: Path
    state: Path
    env: dict[str, str]

    def run(self, *args: str, stdin: bytes = b"") -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(
            ["bash", str(REPORTER), *args],
            input=stdin,
            capture_output=True,
            env=self.env,
            timeout=20,
            umask=0,
            check=False,
        )

    def queued(self) -> list[Path]:
        return sorted(self.state.glob("*.json"))


@pytest.fixture
def reporter(tmp_path: Path, endpoint: Endpoint) -> Reporter:
    assert REPORTER.is_file(), f"Reporter is not available yet: {REPORTER}"
    for command in ("bash", "curl", "jq", "uuidgen"):
        assert shutil.which(command), f"Required command is missing: {command}"
    config = tmp_path / "config.json"
    config.write_text(json.dumps({"url": endpoint.url}))
    env = os.environ.copy()
    env.update(
        T3_FINDINGS_CONFIG=str(config),
        T3_FINDINGS_STATE_DIR=str(tmp_path / "state"),
        HOME=str(tmp_path),
        XDG_CONFIG_HOME=str(tmp_path / "config"),
        XDG_STATE_HOME=str(tmp_path / "xdg-state"),
        NO_PROXY="*",
        no_proxy="*",
    )
    return Reporter(config, tmp_path / "state", env)


@pytest.fixture
def finding() -> bytes:
    return FINDING.read_bytes()


def payload(raw: bytes, finding: bytes) -> dict[str, str]:
    value = json.loads(raw)
    assert set(value) == {"reportId", "error"}
    assert isinstance(value["reportId"], str)
    UUID(value["reportId"])
    assert value["error"] == finding.decode()
    return value


def assert_pending(
    result: subprocess.CompletedProcess[bytes], endpoint: Endpoint
) -> None:
    assert result.returncode == 1, result
    output = result.stdout + result.stderr
    assert b"pending" in output.lower(), output
    for secret in (endpoint.url, "private-test-token", "private-query-token"):
        assert secret.encode() not in output, output


def assert_empty(reporter: Reporter) -> None:
    assert reporter.queued() == []
    if reporter.state.exists():
        assert list(reporter.state.iterdir()) == []


def test_failed_post_then_flush_reuses_report_id(
    reporter: Reporter, endpoint: Endpoint, finding: bytes
) -> None:
    endpoint.status = 503
    assert_pending(reporter.run(stdin=finding), endpoint)
    (queued_file,) = reporter.queued()
    queued = payload(queued_file.read_bytes(), finding)
    assert [payload(raw, finding) for raw in endpoint.requests] == [queued]

    endpoint.status = 200
    result = reporter.run("--flush", stdin=finding)
    assert result.returncode == 0, result
    assert [payload(raw, finding) for raw in endpoint.requests] == [queued, queued]
    assert_empty(reporter)


@pytest.mark.parametrize("status", [200, 201, 202, 204, 206, 299])
def test_every_2xx_deletes_the_report(
    reporter: Reporter, endpoint: Endpoint, finding: bytes, status: int
) -> None:
    endpoint.status = status
    result = reporter.run(stdin=finding)
    assert result.returncode == 0, result
    (request,) = endpoint.requests
    payload(request, finding)
    assert_empty(reporter)


@pytest.mark.parametrize("status", [302, 400, 401, 403, 429, 500])
def test_non_2xx_retains_the_report_without_leaking_url(
    reporter: Reporter, endpoint: Endpoint, finding: bytes, status: int
) -> None:
    endpoint.status = status
    assert_pending(reporter.run(stdin=finding), endpoint)
    (queued_file,) = reporter.queued()
    queued = payload(queued_file.read_bytes(), finding)
    assert [payload(raw, finding) for raw in endpoint.requests] == [queued]


def test_transport_failure_retains_the_report(
    reporter: Reporter, endpoint: Endpoint, finding: bytes
) -> None:
    with socket.socket() as unavailable:
        unavailable.bind(("127.0.0.1", 0))
        port = unavailable.getsockname()[1]
        endpoint.url = f"http://127.0.0.1:{port}/private-test-token"
        reporter.config.write_text(json.dumps({"url": endpoint.url}))
        assert_pending(reporter.run(stdin=finding), endpoint)
    (queued_file,) = reporter.queued()
    payload(queued_file.read_bytes(), finding)
    assert endpoint.requests == []


@pytest.mark.parametrize("config_kind", ["missing", "malformed", "no_url", "bad_url"])
def test_bad_config_retains_report_for_later_flush(
    reporter: Reporter, endpoint: Endpoint, finding: bytes, config_kind: str
) -> None:
    match config_kind:
        case "missing":
            reporter.config.unlink()
        case "malformed":
            reporter.config.write_text('{"url": "' + endpoint.url)
        case "no_url":
            reporter.config.write_text("{}")
        case "bad_url":
            reporter.config.write_text(json.dumps({"url": [endpoint.url]}))

    assert_pending(reporter.run(stdin=finding), endpoint)
    (queued_file,) = reporter.queued()
    queued = payload(queued_file.read_bytes(), finding)
    assert endpoint.requests == []

    reporter.config.write_text(json.dumps({"url": endpoint.url}))
    result = reporter.run("--flush")
    assert result.returncode == 0, result
    assert [payload(raw, finding) for raw in endpoint.requests] == [queued]
    assert_empty(reporter)


@pytest.mark.parametrize("args,stdin", [((), b""), (("--flush",), b"ignored\n")])
@pytest.mark.parametrize("missing_config", [False, True])
def test_empty_input_or_empty_flush_creates_no_finding(
    reporter: Reporter,
    endpoint: Endpoint,
    args: tuple[str, ...],
    stdin: bytes,
    missing_config: bool,
) -> None:
    if missing_config:
        reporter.config.unlink()
    result = reporter.run(*args, stdin=stdin)
    assert result.returncode == 0, result
    assert endpoint.requests == []
    assert_empty(reporter)


@pytest.mark.parametrize("queued", [False, True])
def test_flush_does_not_wait_for_stdin(
    reporter: Reporter, endpoint: Endpoint, finding: bytes, queued: bool
) -> None:
    if queued:
        endpoint.status = 503
        assert_pending(reporter.run(stdin=finding), endpoint)
        endpoint.status = 200

    process = subprocess.Popen(
        ["bash", str(REPORTER), "--flush"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=reporter.env,
    )
    try:
        process.wait(timeout=5)
    finally:
        if process.poll() is None:
            process.kill()
        stdout, stderr = process.communicate(timeout=5)
    assert process.returncode == 0, (stdout, stderr)
    assert len(endpoint.requests) == (2 if queued else 0)
    assert_empty(reporter)


def test_complete_private_queue_exists_before_http_finishes(
    reporter: Reporter, endpoint: Endpoint, finding: bytes
) -> None:
    endpoint.release.clear()
    process = subprocess.Popen(
        ["bash", str(REPORTER)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=reporter.env,
        umask=0,
    )
    try:
        assert process.stdin is not None
        process.stdin.write(finding)
        process.stdin.close()
        process.stdin = None
        assert endpoint.received.wait(timeout=10), "No local HTTP request received"
        (queued_file,) = reporter.queued()
        queued = payload(queued_file.read_bytes(), finding)
        assert payload(endpoint.requests[0], finding) == queued
        assert stat.S_IMODE(reporter.state.stat().st_mode) == 0o700
        assert stat.S_IMODE(queued_file.stat().st_mode) == 0o600
        assert list(reporter.state.iterdir()) == [queued_file]
    finally:
        endpoint.release.set()
        try:
            stdout, stderr = process.communicate(timeout=20)
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()
            raise
    assert process.returncode == 0, (stdout, stderr)
    assert_empty(reporter)
