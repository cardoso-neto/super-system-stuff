# macOS job runner

Reusable command wrapper for Unified Logging and timeouts.
Requires macOS and Xcode Command Line Tools to build; the installed binary has no package-manager dependencies.

```sh
bash shared/job-runner/install.sh
~/.local/bin/job-runner --name example --timeout 30m -- /bin/bash /path/to/job.sh
```

- `--timeout`: positive seconds, optionally suffixed with `s`, `m`, or `h`.
- Exit status: command status; `124` on timeout; `128 + signal` on interruption; `2` for invalid arguments; `126`/`127` for launch failures.
- Shutdown: TERM, then KILL after five seconds for surviving tracked descendants, including separate process groups.
- Scripts write normally to stdout/stderr; remove internal log-file redirection.
- stdout/stderr are mirrored to the caller when writable. A blocked mirror cannot stall logging or the timeout.
- Fully detached processes that escape observation are outside the runner's lifecycle.

## Logs

```sh
log show --last 1d --style compact --predicate 'subsystem == "local.nei.jobs" AND eventMessage BEGINSWITH "job=machine-autoupdate "'
log stream --level default --predicate 'subsystem == "local.nei.jobs"'
```

Events contain `job=NAME run=UUID`; categories are `stdout`, `stderr`, and `lifecycle`.
Output uses default-level persistence and public text so Console and `log show` can display it.
Long lines are split into bounded events; partial final lines are retained.
macOS controls retention and may drop events under load; this is not a lossless archive.

## Launchd integration

Use the runner's absolute path as `ProgramArguments[0]`, followed by the arguments above.
Set `ExitTimeOut` longer than the five-second termination grace period.
Direct the runner's mirrored stdout/stderr to `/dev/null`; Unified Logging is the log destination.

- [Updater installer](../../hosts/mbp/install/autoupdate-install.sh): `bash hosts/mbp/install/autoupdate-install.sh [timeout]`.
- [Updater](../../hosts/mbp/bin/autoupdate.sh): direct execution also uses the runner; `MACHINE_AUTOUPDATE_TIMEOUT` overrides its direct-run default.
- [Integration tests](tests/run.pl): `perl shared/job-runner/tests/run.pl "$HOME/.local/bin/job-runner"`.
