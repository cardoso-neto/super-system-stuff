use strict;
use warnings;
open my $pids, '>', "$ARGV[0]/pids" or die $!;
print {$pids} "$$\n";
close $pids;
$| = 1;
print 'x' x 262144;
sleep 60;
