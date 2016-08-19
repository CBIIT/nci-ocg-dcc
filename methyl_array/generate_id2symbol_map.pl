#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(fileparse);
use Sort::Key qw(nkeysort);

print "Parsing $ARGV[0] and generating map\n";
my %col_idx;
my $probesets_processed = 0;
open(my $annot_csv_fh, '<', $ARGV[0]) 
    or die "\n\nERROR: could not open input annotation file: $!\n\n";
open(my $map_fh, '>', fileparse($ARGV[0], qr/\.[^.]*/) . "_id2symbol_map.txt") 
    or die "\n\nERROR: could not create output mapping file: $!\n\n";
print $map_fh "Reporter ID\tSymbols\n";
while(<$annot_csv_fh>) {
    s/^\s+//;
    s/\s+$//;   
    # column header
    if (m/^!platform_table_begin/i) {
        my @col_names = split /\t/, <$annot_csv_fh>;
        for my $i (0 .. $#col_names) {
            $col_names[$i] =~ s/\s+//g;
            if ($col_names[$i] =~ /^id$/i) {
                $col_idx{id} = $i;
            }
            elsif ($col_names[$i] =~ /^(entrez|)(_| |)gene(_| |)id$/i) {
                $col_idx{gene_id} = $i;
            }
            elsif ($col_names[$i] =~ /^((gene|)(_| |)symbol|UCSC_RefGene_Name)$/i) {
                $col_idx{gene_symbol} = $i;
            }
            elsif ($col_names[$i] =~ /^refseq(_id| id|)$/i) {
                $col_idx{refseq_id} = $i;
            }
            elsif ($col_names[$i] =~ /^(accession|gb_acc)$/i) {
                $col_idx{accession} = $i;
            }
            elsif ($col_names[$i] =~ /^gb(_| |)list$/i) {
                $col_idx{accession_list} = $i;
            }         
            elsif ($col_names[$i] =~ /^unigene(_| |)id$/i) {
                $col_idx{unigene_id} = $i;
            }
            elsif ($col_names[$i] =~ /^spot(_id| id|)$/i) {
                $col_idx{spot_id} = $i;
            }
        }
    }
    # file header
    elsif (m/^(\^|#|!)/) {
        next;
    }
    # data table
    else {
        my @col_data = split /\t/;
        s/\s+//g for @col_data;
        my $unique_gene_symbols_tsv;
        if (defined $col_idx{gene_symbol} and $col_data[$col_idx{gene_symbol}]) {
            my @gene_symbols = split /;/, $col_data[$col_idx{gene_symbol}];
            my %unique_gene_symbols;
            for my $i (0 .. $#gene_symbols) {
                if (not exists $unique_gene_symbols{$gene_symbols[$i]}) {
                    $unique_gene_symbols{$gene_symbols[$i]} = $i;
                }
            }
            $unique_gene_symbols_tsv = join(";", nkeysort { $unique_gene_symbols{$_} } keys %unique_gene_symbols);
        }
        print $map_fh "$col_data[$col_idx{id}]\t", $unique_gene_symbols_tsv || '', "\n";
        $probesets_processed++;
    }
}
close($annot_csv_fh);
close($map_fh);
print "$probesets_processed probesets processed\n";
exit;

