#!/usr/bin/env perl

use strict;
use warnings;

my $manifest_delimiter_regexp = qr/(?: (?:\*| )?)/;

my %checksums;
open(my $fh, '<', shift @ARGV) or die "ERROR: $!";
while (<$fh>) {
    next if m/^\s*$/;
    s/\s+$//;
    my ($checksum, $file_rel_path) = split /$manifest_delimiter_regexp/, $_, 2;
    $checksums{$checksum}++ unless exists $checksums{$checksum};
}
close($fh);
print scalar(keys %checksums), "\n";
