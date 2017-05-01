#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../common/lib/perl5";
use NCI::OCGDCC::Utils qw( manifest_by_file_path );
use Sort::Key::Natural qw( natsort );
use Term::ANSIColor;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;
#$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = sub {
    my ($hashref) = @_;
    my @sorted_keys = natsort keys %{$hashref};
    return \@sorted_keys;
};

open(my $in_fh, '<', $ARGV[0]) or die $!;
my @manifest_entries = map { s/\s+$//; $_ } <$in_fh>;
close($in_fh);
my @sorted_manifest_entries = sort manifest_by_file_path @manifest_entries;
open(my $out_fh, '>', $ARGV[0]) or die $!;
print $out_fh join("\n", @sorted_manifest_entries), "\n";
close($out_fh);
exit;
