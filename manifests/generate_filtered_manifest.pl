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
my $default_manifest_file_name = $config_hashref->{'manifests'}->{'default_manifest_file_name'};
my $manifest_delimiter_regexp = $config_hashref->{'manifests'}->{'manifest_delimiter_regexp'};

my ($in_dir, $out_dir) = @ARGV;
opendir(my $dh, $out_dir) or die "ERROR: $!";
my %file_names = map { $_ => 1 } grep { !m/^\./ and -f "$out_dir/$_" } readdir($dh);
closedir($dh);
open(my $in_fh, '<', "$in_dir/$default_manifest_file_name")
    or die "ERROR: could not open $in_dir/$default_manifest_file_name: $!";
open(my $out_fh, '>', "$out_dir/$default_manifest_file_name")
    or die "ERROR: could not create $out_dir/$default_manifest_file_name: $!";
while (<$in_fh>) {
    next if m/^\s*$/;
    s/\s+$//;
    my ($manifest_checksum, $manifest_delimiter, $file_name) = split /$manifest_delimiter_regexp/, $_, 2;
    if (exists $file_names{$file_name}) {
        print $out_fh "$_\n";
    }
}
close($in_fh);
exit;
