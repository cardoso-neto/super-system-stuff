use strict;
use warnings;
binmode STDOUT;
binmode STDERR;
my $pid = fork();
die $! unless defined $pid;
if (!$pid) { print STDERR 'e' x 262144, "\nerror tail"; exit 0; }
print STDOUT 'o' x 262144, "\noutput tail";
waitpid $pid, 0;
exit 23;
