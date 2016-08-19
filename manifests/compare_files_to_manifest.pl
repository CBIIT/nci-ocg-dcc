#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;

my %manifest_barcodes;
open(my $fh, '<', 'MANIFEST.txt') or die "$!";
while (<$fh>) {
    chomp;
    my ($checksum, $file_name) = split / (?:\*| )/, $_, 2;
    my ($barcode) = $file_name =~ /($BARCODE_REGEXP)/i;
    $manifest_barcodes{$barcode}++;
}
close($fh);
opendir(my $dh, $ENV{PWD}) or die "$!";
my @file_barcodes = map { m/($BARCODE_REGEXP)/i; } grep { -f and m/\.bam$/ } readdir($dh);
closedir($dh);
for my $file_barcode (@file_barcodes) {
    if (!exists $manifest_barcodes{$file_barcode}) {
        print "$file_barcode\n";
    }
}
