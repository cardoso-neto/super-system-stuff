use strict;
use warnings;
use POSIX qw(setsid);
my ($directory) = @ARGV;
$SIG{TERM} = 'IGNORE';
open my $parent_pid, '>', "$directory/pids" or die $!;
print {$parent_pid} "$$\n";
close $parent_pid;
my $pid = fork();
die $! unless defined $pid;
if (!$pid) {
    setsid() >= 0 or die "setsid: $!";
    open my $pids, '>>', "$directory/pids" or die $!;
    print {$pids} "$$\n";
    close $pids;
    open my $ready, '>', "$directory/ready" or die $!;
    close $ready;
    sleep 60;
    exit 0;
}
sleep 60;
