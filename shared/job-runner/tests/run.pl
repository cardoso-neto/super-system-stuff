#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::Temp qw(tempdir);
use JSON::PP qw(decode_json);
use Encode qw(encode_utf8);
use POSIX qw(WNOHANG);
use Time::HiRes qw(time sleep);

my ($runner, $filter) = @ARGV;
die "Usage: $0 /absolute/path/to/job-runner [fixture-name]\n" unless defined $runner && -x $runner;
my @fixtures = glob "$FindBin::Bin/fixtures/*.json";
@fixtures = grep /\Q$filter\E/, @fixtures if defined $filter;
die "No fixtures selected\n" unless @fixtures;
my $failures = 0;
for my $fixture (@fixtures) {
    my $case = decode_json(read_file($fixture));
    my $temp = tempdir(CLEANUP => 1);
    my @arguments = map { my $arg = $_; $arg =~ s/\@FIXTURE\@/$FindBin::Bin\/fixtures/g; $arg =~ s/\@TMP\@/$temp/g; $arg } @{$case->{arguments}};
    print "RUN $fixture\n";
    my $started = time;
    my ($blocked_reader, $blocked_writer);
    pipe($blocked_reader, $blocked_writer) or die $! if $case->{blocked_stdout};
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        if ($case->{blocked_stdout}) {
            close $blocked_reader;
            open STDOUT, '>&', $blocked_writer or die $!;
            close $blocked_writer;
        } else { open STDOUT, '>', "$temp/stdout" or die $!; }
        if ($case->{merged_stderr}) { open STDERR, '>&', STDOUT or die $!; }
        else { open STDERR, '>', "$temp/stderr" or die $!; }
        exec {$runner} $runner, @arguments;
        die "exec: $!";
    }
    close $blocked_writer if $case->{blocked_stdout};
    my ($status, $sent_signal);
    while (1) {
        if (waitpid($pid, WNOHANG) == $pid) { $status = $?; last; }
        if ($case->{signal} && !$sent_signal && -f "$temp/ready") {
            sleep 0.2;
            kill $case->{signal}, $pid;
            $sent_signal = 1;
        }
        if (time - $started > 20) {
            kill 'KILL', $pid;
            waitpid($pid, 0);
            $status = $?;
            last;
        }
        sleep 0.03;
    }
    my @errors;
    my $exit = $status & 127 ? 128 + ($status & 127) : $status >> 8;
    push @errors, "exit $exit, expected $case->{exit}" if $exit != $case->{exit};
    for my $stream (qw(stdout stderr)) {
        next unless exists $case->{$stream};
        my $expected = $case->{$stream};
        $expected = ($expected->{unit} x $expected->{count}) . ($expected->{tail} // '') if ref $expected;
        $expected = encode_utf8($expected);
        my $actual = read_file("$temp/$stream");
        push @errors, "$stream differs (got " . length($actual) . ", expected " . length($expected) . " bytes)" if $actual ne $expected;
    }
    if ($case->{descendants}) {
        if (!-f "$temp/pids") { push @errors, 'descendant PID file missing'; }
        else {
            for my $child (split /\s+/, read_file("$temp/pids")) {
                next unless $child =~ /^\d+$/;
                my $deadline = time + 2;
                sleep 0.05 while kill(0, $child) && time < $deadline;
                if (kill 0, $child) {
                    push @errors, "descendant $child remains alive";
                    kill 'KILL', $child;
                }
            }
        }
    }
    if (@errors) {
        $failures++;
        print "FAIL: ", join('; ', @errors), "\n";
        print "STDERR: ", read_file("$temp/stderr"), "\n" if -f "$temp/stderr";
    } else { printf "PASS (%.2fs)\n", time - $started; }
}
print scalar(@fixtures), " cases, $failures failures\n";
exit($failures ? 1 : 0);

sub read_file {
    my ($path) = @_;
    open my $file, '<', $path or die "$path: $!";
    local $/;
    return <$file> // '';
}
