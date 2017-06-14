#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Spec;
use Sort::Key::Natural;
use Sort::Key::Maker nat2_keysort => qw(natural natural);

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;

open(my $in_fh, '<', "$FindBin::Bin/samplemetadata.csv");
my $header = <$in_fh>;
$header =~ s/\s+$//;
my @header_fields = split(',', $header);
s/(^"|"$)//g for @header_fields;
$header_fields[1] = 's_case_id';
$header_fields[2] = 'barcode';
$header_fields[5] = 'software_version';
$header_fields[14] = 'capture_kit';
$header_fields[15] = 'readgroup';
my @data_arrayref;
while (<$in_fh>) {
    s/\s+$//;
    my @fields = split ',';
    s/(^"|"$)//g for @fields;
    $fields[2] =~ s/_/-/g;
    $fields[2] = uc($fields[2]);
    if ($fields[2] !~ /^$BARCODE_REGEXP$/i) {
        $fields[2] .= 'D';
        if ($fields[2] !~ /^$BARCODE_REGEXP$/i) {
            die "ERROR: invalid barcode $fields[2]\n";
        }
    }
    push @data_arrayref, \@fields;
}
close($in_fh);
my $submission_label = pop @{[File::Spec->splitdir($FindBin::Bin)]};
open(my $out_fh, '>', "$FindBin::Bin/${submission_label}_metadata.txt");
print $out_fh join("\t", @header_fields), "\n";
for my $row_arrayref (nat2_keysort { $_->[0], $_->[2] } @data_arrayref) {
    print $out_fh join("\t", @{$row_arrayref}), "\n";
}
close($out_fh);
exit;
