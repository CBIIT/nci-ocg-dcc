#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use NCI::OCGDCC::Utils qw( load_configs );
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;
#$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = sub {
    my ($hashref) = @_;
    my @sorted_keys = natsort keys %{$hashref};
    return \@sorted_keys;
};

# config
my $config_hashref = load_configs(qw(
    manifests
));
my $manifest_delimiter_regexp = $config_hashref->{'manifests'}->{'manifest_delimiter_regexp'};

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
exit;
