import Darwin
import Foundation
import OSLog

nonisolated(unsafe) var receivedSignal: Int32 = 0

struct Options {
    let name: String
    let timeout: Double
    let command: [String]

    init(_ arguments: [String]) throws {
        var name: String?
        var timeout: Double?
        var index = 0
        while index < arguments.count && arguments[index] != "--" {
            guard index + 1 < arguments.count else { throw RunnerError.usage }
            let value = arguments[index + 1]
            switch arguments[index] {
            case "--name": name = value
            case "--timeout":
                let suffix = value.last
                let multiplier: Double = suffix == "h" ? 3600 : suffix == "m" ? 60 : 1
                let number = ["s", "m", "h"].contains(suffix.map(String.init) ?? "")
                    ? String(value.dropLast()) : value
                guard let duration = Double(number), duration.isFinite, duration > 0,
                      (duration * multiplier).isFinite else { throw RunnerError.usage }
                timeout = duration * multiplier
            default: throw RunnerError.usage
            }
            index += 2
        }
        guard let name, !name.isEmpty, name.utf8.count <= 128,
              name.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }),
              let timeout, index < arguments.count, arguments[index] == "--",
              index + 1 < arguments.count else { throw RunnerError.usage }
        self.name = name
        self.timeout = timeout
        command = Array(arguments.dropFirst(index + 1))
    }
}

enum RunnerError: Error {
    case usage
    case system(String, Int32)
}

struct Events {
    let prefix: String
    let lifecycle = Logger(subsystem: "local.nei.jobs", category: "lifecycle")

    init(name: String) {
        prefix = "job=\(name) run=\(UUID().uuidString)"
    }

    func record(_ message: String, error: Bool = false) {
        let text = "\(prefix) \(message)"
        if error { lifecycle.error("\(text, privacy: .public)") }
        else { lifecycle.notice("\(text, privacy: .public)") }
    }
}

final class Output {
    let descriptor: Int32
    let destination: Int32
    let logger: Logger
    let prefix: String
    var buffer: [UInt8] = []
    var closed = false

    init(descriptor: Int32, destination: Int32, category: String, prefix: String) {
        self.descriptor = descriptor
        self.destination = destination
        self.prefix = prefix
        logger = Logger(subsystem: "local.nei.jobs", category: category)
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
    }

    func drain() {
        var bytes = [UInt8](repeating: 0, count: 8192)
        // Bound each pass so continuous output cannot starve the timeout check.
        for _ in 0..<16 {
            let count = read(descriptor, &bytes, bytes.count)
            if count == 0 { finish(); return }
            if count < 0 {
                if errno == EINTR { continue }
                if errno != EAGAIN { finish() }
                return
            }
            bytes.withUnsafeBytes { raw in
                var offset = 0
                while offset < count {
                    let written = write(destination, raw.baseAddress!.advanced(by: offset), count - offset)
                    if written < 0 && errno == EINTR { continue }
                    if written <= 0 { break }
                    offset += written
                }
            }
            buffer.append(contentsOf: bytes.prefix(count))
            emitLines()
        }
    }

    func emitLines(final: Bool = false) {
        while !buffer.isEmpty {
            if let newline = buffer.firstIndex(of: 10), newline < 700 {
                emit(Array(buffer.prefix(newline)))
                buffer.removeFirst(newline + 1)
            } else if buffer.count > 700 {
                var boundary = 700
                while boundary > 0 && boundary < buffer.count && buffer[boundary] & 0xC0 == 0x80 {
                    boundary -= 1
                }
                if boundary == 0 { boundary = 700 }
                emit(Array(buffer.prefix(boundary)))
                buffer.removeFirst(boundary)
            } else if final {
                emit(buffer)
                buffer.removeAll()
            } else { break }
        }
    }

    func emit(_ bytes: [UInt8]) {
        let message = "\(prefix) \(String(decoding: bytes, as: UTF8.self))"
        logger.notice("\(message, privacy: .public)")
    }

    func finish() {
        guard !closed else { return }
        emitLines(final: true)
        close(descriptor)
        closed = true
    }
}

struct ProcessIdentity: Hashable {
    let pid: pid_t
    let seconds: UInt64
    let microseconds: UInt64

    init?(_ pid: pid_t) {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.stride)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        self.pid = pid
        seconds = info.pbi_start_tvsec
        microseconds = info.pbi_start_tvusec
    }

    func send(_ signal: Int32) {
        if ProcessIdentity(pid) == self { kill(pid, signal) }
    }
}

func descendants(of pid: pid_t) -> Set<ProcessIdentity> {
    var result = Set<ProcessIdentity>()
    var pending = [pid]
    while let parent = pending.popLast() {
        var capacity = 64
        while true {
            var children = [pid_t](repeating: 0, count: capacity)
            let count = proc_listchildpids(parent, &children, Int32(capacity * MemoryLayout<pid_t>.stride))
            if count == capacity { capacity *= 2; continue }
            for child in children.prefix(max(0, Int(count))) {
                if let identity = ProcessIdentity(child), result.insert(identity).inserted {
                    pending.append(child)
                }
            }
            break
        }
    }
    return result
}

func spawn(_ command: [String]) throws -> (pid_t, Int32, Int32) {
    var out: [Int32] = [0, 0]
    var err: [Int32] = [0, 0]
    guard pipe(&out) == 0 else { throw RunnerError.system("pipe", errno) }
    guard pipe(&err) == 0 else {
        close(out[0]); close(out[1])
        throw RunnerError.system("pipe", errno)
    }
    var actions: posix_spawn_file_actions_t?
    var attributes: posix_spawnattr_t?
    posix_spawn_file_actions_init(&actions)
    posix_spawnattr_init(&attributes)
    defer {
        posix_spawn_file_actions_destroy(&actions)
        posix_spawnattr_destroy(&attributes)
        close(out[1]); close(err[1])
    }
    posix_spawn_file_actions_adddup2(&actions, out[1], STDOUT_FILENO)
    posix_spawn_file_actions_adddup2(&actions, err[1], STDERR_FILENO)
    for descriptor in out + err { posix_spawn_file_actions_addclose(&actions, descriptor) }
    posix_spawnattr_setpgroup(&attributes, 0)
    var defaults: sigset_t = 0
    for signal in [SIGINT, SIGTERM, SIGPIPE] { sigaddset(&defaults, signal) }
    var mask: sigset_t = 0
    posix_spawnattr_setsigdefault(&attributes, &defaults)
    posix_spawnattr_setsigmask(&attributes, &mask)
    posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_SETSIGDEF | POSIX_SPAWN_SETSIGMASK))
    var argv = command.map { strdup($0) } + [nil]
    var environment = ProcessInfo.processInfo.environment.map { strdup("\($0.key)=\($0.value)") } + [nil]
    defer { for pointer in argv + environment { free(pointer) } }
    var pid: pid_t = 0
    let status = posix_spawnp(&pid, command[0], &actions, &attributes, &argv, &environment)
    guard status == 0 else {
        close(out[0]); close(err[0])
        throw RunnerError.system("spawn \(command[0])", status)
    }
    return (pid, out[0], err[0])
}

func elapsedSeconds(since start: ContinuousClock.Instant) -> Double {
    let duration = start.duration(to: ContinuousClock.now).components
    return Double(duration.seconds) + Double(duration.attoseconds) / 1e18
}

func run(_ options: Options) -> Int32 {
    let events = Events(name: options.name)
    let started = ContinuousClock.now
    events.record("started timeout=\(options.timeout)s executable=\(options.command[0])")
    do {
        signal(SIGTERM) { receivedSignal = $0 }
        signal(SIGINT) { receivedSignal = $0 }
        signal(SIGPIPE, SIG_IGN)
        let (pid, stdout, stderr) = try spawn(options.command)
        let destinations = [STDOUT_FILENO, STDERR_FILENO]
        let destinationFlags = destinations.map { fcntl($0, F_GETFL) }
        for (descriptor, flags) in zip(destinations, destinationFlags) {
            _ = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK)
        }
        defer {
            for (descriptor, flags) in zip(destinations, destinationFlags) {
                _ = fcntl(descriptor, F_SETFL, flags)
            }
        }
        let outputs = [Output(descriptor: stdout, destination: STDOUT_FILENO, category: "stdout", prefix: events.prefix),
                       Output(descriptor: stderr, destination: STDERR_FILENO, category: "stderr", prefix: events.prefix)]
        var status: Int32 = 0
        var reaped = false
        var forcedExit: Int32?
        var stopTime: Double?
        var tracked = Set<ProcessIdentity>()
        if let root = ProcessIdentity(pid) { tracked.insert(root) }
        var lastScan = -Double.infinity
        while true {
            let now = elapsedSeconds(since: started)
            if now - lastScan >= 0.2 {
                tracked = Set(tracked.filter { ProcessIdentity($0.pid) == $0 })
                for process in Array(tracked) { tracked.formUnion(descendants(of: process.pid)) }
                lastScan = now
            }
            for output in outputs where !output.closed { output.drain() }
            if !reaped { reaped = waitpid(pid, &status, WNOHANG) == pid }
            if forcedExit == nil && receivedSignal != 0 {
                forcedExit = 128 + receivedSignal
                events.record("terminated signal=\(receivedSignal)", error: true)
            }
            if forcedExit == nil && now >= options.timeout && !(reaped && outputs.allSatisfy(\.closed)) {
                forcedExit = 124
                events.record("timed out after \(options.timeout)s", error: true)
            }
            if forcedExit != nil && stopTime == nil {
                stopTime = now
                kill(-pid, SIGTERM)
                for process in tracked { process.send(SIGTERM) }
            }
            if let stopTime, now - stopTime >= 5 {
                kill(-pid, SIGKILL)
                for process in tracked { process.send(SIGKILL) }
                if !reaped { while waitpid(pid, &status, 0) < 0 && errno == EINTR {} }
                for output in outputs where !output.closed { output.drain(); output.finish() }
                break
            }
            if reaped && outputs.allSatisfy(\.closed) {
                if forcedExit == nil || !tracked.contains(where: { ProcessIdentity($0.pid) == $0 }) { break }
            }
            usleep(20_000)
        }
        let exitCode = forcedExit ?? ((status & 0x7f) == 0 ? (status >> 8) & 0xff : 128 + (status & 0x7f))
        let elapsed = String(format: "%.3f", elapsedSeconds(since: started))
        events.record("finished exit=\(exitCode) duration=\(elapsed)s", error: exitCode != 0)
        return exitCode
    } catch {
        events.record("failed to start: \(error)", error: true)
        fputs("job-runner: \(error)\n", Darwin.stderr)
        if case RunnerError.system(_, let code) = error { return code == ENOENT ? 127 : 126 }
        return 126
    }
}

do {
    let options = try Options(Array(CommandLine.arguments.dropFirst()))
    exit(run(options))
} catch {
    fputs("Usage: job-runner --name NAME --timeout DURATION -- COMMAND [ARG ...]\nDURATION: positive seconds, or a value ending in s, m, or h (e.g. 30m, 4h).\n", stderr)
    exit(2)
}
