#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# config
my $default_manifest_file_name = 'MANIFEST.txt';
my $manifest_delimiter_regexp = qr/( (?:\*| )?)/;

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
