#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use List::Util qw(none);

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
open(my $in_fh, '<', "$FindBin::Bin/sequence_metadata.csv")
    or die "ERROR: could not open sequence_metadata.csv: $!";
<$in_fh>;
my %add_metadata_by_library_id;
while (<$in_fh>) {
    s/\s+$//;
    my @fields = split(',');
    # skip non-WXS rows
    next unless $fields[2] and $fields[2] ne 'None';
    $fields[2] =~ s/_/ /g;
    if (!defined $add_metadata_by_library_id{$fields[1]}) {
        $add_metadata_by_library_id{$fields[1]} = {
            hybrid_selection_kit => $fields[2],
            sequencer => [ $s_model_by_name{$fields[3]} ],
            run_date => [ $fields[4] ],
        };
    }
    else {
        if (none { $fields[4] eq $_ } @{$add_metadata_by_library_id{$fields[1]}{run_date}}) {
            push @{$add_metadata_by_library_id{$fields[1]}{run_date}}, $fields[4];
        }
        if (none { $s_model_by_name{$fields[3]} eq $_ } @{$add_metadata_by_library_id{$fields[1]}{sequencer}}) {
            push @{$add_metadata_by_library_id{$fields[1]}{sequencer}}, $s_model_by_name{$fields[3]};
        }
    }
}
close($in_fh);
open(my $out_fh, '>', "$FindBin::Bin/target_os_wxs_nci_meltzer_add_metadata.txt");
print $out_fh join("\t", qw(
    library_id
    sequencer
    run_date
    design_description
)), "\n";
for my $library_id (sort { $a <=> $b } keys %add_metadata_by_library_id) {
    my $design_desc = <<"    DD_TEXT";
    Genomic DNA was isolated using the Qiagen AllPrep Kit.
    Conventional Illumina DNA sequencing libraries for whole exome sequencing were prepared using 1 mcg genomic DNA fragmented to a mean size of approximately 350 bp in an S1 Covaris Sonicator.
    Exome sequence was captured for Illumina sequencing following the manufacturers' instructions using $add_metadata_by_library_id{$library_id}{hybrid_selection_kit}.
    Each library underwent 101-cycle paired-end sequencing.
    DD_TEXT
    $design_desc =~ s/\s+/ /g;
    print $out_fh join("\t", (
        $library_id,
        join(',', @{$add_metadata_by_library_id{$library_id}{sequencer}}),
        join(',', @{$add_metadata_by_library_id{$library_id}{run_date}}),
        #$design_desc,
    )), "\n";
}
close($out_fh);
exit;
