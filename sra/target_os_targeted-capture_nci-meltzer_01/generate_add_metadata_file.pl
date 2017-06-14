#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Spec;
use List::Util qw( none );
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

open(my $s_fh, '<', "$FindBin::Bin/sequencers.csv")
    or die "ERROR: could not open sequencers.csv: $!";
<$s_fh>;
my %s_model_by_name;
while (<$s_fh>) {
    s/\s+$//;
    my ($name, $model) = split(',');
    $s_model_by_name{$name} = $model;
}
close($s_fh);
open(my $in_fh, '<', "$FindBin::Bin/samplemetadata.csv")
    or die "ERROR: could not open samplemetadata.csv: $!";
<$in_fh>;
my %add_metadata_by_library_id;
while (<$in_fh>) {
    s/\s+$//;
    my @fields = split(',');
    $fields[14] =~ s/_/ /g;
    if (!defined($add_metadata_by_library_id{$fields[9]})) {
        $add_metadata_by_library_id{$fields[9]} = {
            capture_kit => $fields[14],
            sequencer => [ $s_model_by_name{$fields[8]} ],
            run_date => [ $fields[7] ],
        };
        
        if (!defined($s_model_by_name{$fields[8]})) {
            print "$fields[8]";
            <STDIN>;
        }
    }
    else {
        if (none { $fields[7] eq $_ } @{$add_metadata_by_library_id{$fields[9]}{run_date}}) {
            push @{$add_metadata_by_library_id{$fields[9]}{run_date}}, $fields[7];
        }
        if (none { $s_model_by_name{$fields[8]} eq $_ } @{$add_metadata_by_library_id{$fields[9]}{sequencer}}) {
            push @{$add_metadata_by_library_id{$fields[9]}{sequencer}}, $s_model_by_name{$fields[8]};
        }
    }
}
close($in_fh);
my $submission_label = pop @{[File::Spec->splitdir($FindBin::Bin)]};
open(my $out_fh, '>', "$FindBin::Bin/${submission_label}_add_metadata.txt");
print $out_fh join("\t", qw(
    library_id
    sequencer
    run_date
    design_description
)), "\n";
for my $library_id (natsort keys %add_metadata_by_library_id) {
    #my $design_desc = <<"    DD_TEXT";
    #Genomic DNA was isolated using the Qiagen AllPrep Kit.
    #Conventional Illumina DNA sequencing libraries for targeted-capture sequencing were prepared using 1 mcg genomic DNA fragmented to a mean size of approximately 350 bp in an S1 Covaris Sonicator.
    #Exome sequence was captured for Illumina sequencing following the manufacturers' instructions using $add_metadata_by_library_id{$library_id}{capture_kit}.
    #Each library underwent 101-cycle paired-end sequencing.
    #DD_TEXT
    #$design_desc =~ s/\s+/ /g;
    print $out_fh join("\t", (
        $library_id,
        join(',', @{$add_metadata_by_library_id{$library_id}{sequencer}}),
        join(',', @{$add_metadata_by_library_id{$library_id}{run_date}}),
        #$design_desc,
    )), "\n";
}
close($out_fh);
exit;
