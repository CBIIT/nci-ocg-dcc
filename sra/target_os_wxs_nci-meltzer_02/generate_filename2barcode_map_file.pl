#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl5";
use Config::Tiny;
use NCI::OCGDCC::Utils qw( get_barcode_info );
use Sort::Key::Natural qw( natsort );
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
my %case_ccr_tissue2code = (
    'NAAEDH' => {
        'Tumor' => '06',
    },
    '01' => 'Tumor',
    '02' => 'RecurrentTumor',
    '10' => 'Normal',
);

my $config = Config::Tiny->read("$FindBin::Bin/../generate_sra_xml_submission.conf");
die "ERROR: couldn't load config: ", Config::Tiny->errstr unless $config;

my $submission_label = pop @{[File::Spec->splitdir($FindBin::Bin)]};
my $barcode_by_case_tissue_code_hashref;
open(my $barcodes_fh, '<', "$FindBin::Bin/${submission_label}_barcodes.txt")
    or die "ERROR: couldn't open $FindBin::Bin/${submission_label}_barcodes.txt: $!";
while (<$barcodes_fh>) {
    s/\s+$//;
    my ($case_id, $tissue_code) = @{get_barcode_info($_)}{qw( case_id tissue_code )};
    $barcode_by_case_tissue_code_hashref->{$case_id}->{$tissue_code} = $_;
}
close($barcodes_fh);

open(my $map_fh, '>', "$FindBin::Bin/${submission_label}_file_name2barcode_map.txt")
    or die "ERROR: couldn't create $FindBin::Bin/${submission_label}_file_name2barcode_map.txt: $!";
open(my $manifest_fh, '<', "$config->{$submission_label}->{data_dir}/MANIFEST.txt")
    or die "ERROR: couldn't open $config->{$submission_label}->{data_dir}/MANIFEST.txt: $!";

my %types;
while (<$manifest_fh>) {
    s/\s+$//;
    my (undef, $file_name) = split(' \*');
    my ($prefix) = split('\.', $file_name);
    my ($s_case_id, $ccr_tissue_type) = split('_', $prefix);
    my $case_id = "TARGET-40-${s_case_id}";
    $types{$ccr_tissue_type}++;
}
close($manifest_fh);
close($map_fh);


print Dumper(\%types);

exit;
