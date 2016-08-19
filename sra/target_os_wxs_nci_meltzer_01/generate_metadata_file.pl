#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Sort::Key::Natural;
use Sort::Key::Maker nat2_keysort => qw(natural natural);

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;

my %ihrt_barcode_map = (
    'IHRT131-TumourDNA'  => 'TARGET-40-0A4HLD-01A-01D',
    'IHRT131-WBC-DNA'    => 'TARGET-40-0A4HLD-10A-01D',
    'IHRT803-TumourDNA'  => 'TARGET-40-0A4HX8-01A-01D',
    'IHRT803-WBC-DNA'    => 'TARGET-40-0A4HX8-10A-01D',
    'IHRT1173-TumourDNA' => 'TARGET-40-0A4HXS-01A-01D',
    'IHRT1173-WBC-DNA'   => 'TARGET-40-0A4HXS-10A-01D',
    'IHRT1705-TumourDNA' => 'TARGET-40-0A4I0Q-01A-01D',
    'IHRT1705-WBC-DNA'   => 'TARGET-40-0A4I0Q-10A-01D',
    'IHRT2383-WBC-DNA'   => 'TARGET-40-0A4I0S-10A-01D',
    'IHRT2536-TumourDNA' => 'TARGET-40-0A4I0W-01A-01D',
    'IHRT2550-TumourDNA' => 'TARGET-40-0A4I3S-01A-01D',
    'IHRT2550-WBC-DNA'   => 'TARGET-40-0A4I3S-10A-01D',
    'IHRT1165-TumourDNA' => 'TARGET-40-0A4I6O-01A-01D',
    'IHRT1165-WBC-DNA'   => 'TARGET-40-0A4I6O-10A-01D',
    'IHRT3357-TumourDNA' => 'TARGET-40-0A4I8U-01A-01D',
    'IHRT3357-WBC-DNA'   => 'TARGET-40-0A4I8U-10A-01D',
    'IHRT2749-TumourDNA' => 'TARGET-40-0A4I42-01A-01D',
    'IHRT2749-WBC-DNA'   => 'TARGET-40-0A4I42-10A-01D',
);

open(my $in_fh, '<', "$FindBin::Bin/biobase.nih.gov.solexa.12-21-15.basecalldates.csv");
my $header = <$in_fh>;
$header =~ s/\s+$//;
my @header_fields = split(',', $header);
s/(^"|"$)//g for @header_fields;
$header_fields[0] = 's_case_id';
$header_fields[2] = 'barcode';
$header_fields[8] = 'software_version';
my @data_arrayref;
while (<$in_fh>) {
    s/\s+$//;
    my @fields = split ',';
    s/(^"|"$)//g for @fields;
    $fields[2] =~ s/_/-/g;
    if ($fields[2] =~ /^($BARCODE_REGEXP)/i) {
        $fields[2] = uc($1);
        $fields[2] =~ s/W$/Y/;
    }
    elsif (exists($ihrt_barcode_map{$fields[2]})) {
        $fields[2] = $ihrt_barcode_map{$fields[2]};
    }
    push @data_arrayref, \@fields;
}
close($in_fh);
open(my $out_fh, '>', "$FindBin::Bin/target_os_wxs_nci_meltzer_metadata.txt");
print $out_fh join("\t", @header_fields), "\n";
for my $row_arrayref (nat2_keysort { $_->[0], $_->[2] } @data_arrayref) {
    print $out_fh join("\t", @{$row_arrayref}), "\n";
}
close($out_fh);
exit;
