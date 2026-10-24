# T3 findings

`report.sh` queues stdin as a finding, then posts queued findings to a T3 webhook.
Requires Bash, curl, jq, and uuidgen.

Store the webhook URL in `~/.config/t3-findings/webhook.json`:

```json
{"url": "https://your-t3-host/task-webhook-path"}
```

Keep the URL private.
Set the config directory to mode `700` and the config file to `600`.
Do not put the real config in this repository.

```bash
printf 'Updater failed on host-name\n%s\n' "$output" | shared/t3-findings/report.sh
shared/t3-findings/report.sh --flush
```

With no arguments, empty stdin or a terminal creates no finding.
`--flush` ignores stdin and retries the queue.
Both modes attempt delivery of existing findings.
Set `T3_FINDINGS_CONFIG` and `T3_FINDINGS_STATE_DIR` to override the config path and state directory.

Findings are saved as `{ "reportId": "UUID", "error": "stdin text" }` in `~/.local/state/t3-findings` before delivery.
The directory is private (`700`); queued files are private (`600`) and published with an atomic rename.
Each file keeps its original `reportId` across retries.
HTTP `2xx` responses remove the file; other responses and transport failures leave it queued and log a pending delivery message to stderr.
Requests have a 5-second connection timeout and a 15-second total timeout.
The reporter exits `0` when the queue is delivered or empty, `1` on delivery failure, and `2` for invalid arguments.
Delivery diagnostics omit the webhook URL and response body.

Configure the native T3 webhook task with replay key `{{body.reportId}}` to deduplicate retries.
The agent prompt comes from the task:

```text
{{body.error}}

Triage, please.
```

Run the local HTTP integration tests:

```bash
PYTHONDONTWRITEBYTECODE=1 uv run --no-project --with pytest pytest shared/t3-findings/tests
```

The tests use isolated config and state directories and a local HTTP server.
They do not call T3 or create threads.
