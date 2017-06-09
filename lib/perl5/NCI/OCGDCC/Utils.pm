package NCI::OCGDCC::Utils;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../../lib/perl5";
use Config::Any;
use File::Spec;
use List::Util qw( any first max uniq );
use NCI::OCGDCC::Config qw( :all );
use Sort::Key::Natural qw( natsort mkkey_natural );
use Term::ANSIColor;
require Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    load_configs
    get_barcode_info
    get_ncit_disease
    get_ncit_disease_state
    get_ncit_organism_part
    manifest_by_file_path
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.1';

sub load_configs {
    my @types = @_;
    my %config_file_info;
    for my $type (natsort @types) {
        if (
            defined($ENV{PAR_TEMP}) and
            -f "$ENV{PAR_TEMP}/inc/${type}_conf.pl"
        ) {
            $config_file_info{$type} = {
                file => "$ENV{PAR_TEMP}/inc/${type}_conf.pl",
                plugin => 'Config::Any::Perl',
            };
        }
        elsif (
            -f "$SCRIPT_BASE_DIR/$type/conf/${type}_conf.pl"
        ) {
            $config_file_info{$type} = {
                file => "$SCRIPT_BASE_DIR/$type/conf/${type}_conf.pl",
                plugin => 'Config::Any::Perl',
            };
        }
        else {
            die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                ": invalid config type (or forgot to include in compile): $type";
        }
    }
    my @config_files = map { $_->{file} } values %config_file_info;
    my @config_file_plugins = map { $_->{plugin} } values %config_file_info;
    my $config_hashref = Config::Any->load_files({
        files => \@config_files,
        force_plugins => \@config_file_plugins,
        flatten_to_hash => 1,
    });
    # use %config_file_info key instead of file path (saves typing)
    for my $config_file (keys %{$config_hashref}) {
        $config_hashref->{
            first {
                $config_file_info{$_}{file} eq $config_file
            } keys %config_file_info
        } = $config_hashref->{$config_file};
        delete $config_hashref->{$config_file};
    }
    for my $config_key (natsort keys %config_file_info) {
        if (!exists($config_hashref->{$config_key})) {
            die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
            ": could not compile/load $config_file_info{$config_key}{file}\n";
        }
    }
    return $config_hashref;
}

sub get_barcode_info {
    my ($barcode) = @_;
    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid barcode '$barcode'"
        unless $barcode =~ /^$OCG_BARCODE_REGEXP$/;
    my ($case_id, $s_case_id, $sample_id, $disease_code, $tissue_code_str, $nucleic_acid_code_str);
    my @barcode_parts = split('-', $barcode);
    # TARGET sample ID/barcode
    if (scalar(@barcode_parts) == 5) {
        $case_id = join('-', @barcode_parts[0..2]);
        $s_case_id = $barcode_parts[2];
        $sample_id = join('-', @barcode_parts[0..3]);
        ($disease_code, $tissue_code_str, $nucleic_acid_code_str) = @barcode_parts[1,3,4];
    }
    # CGCI sample ID/barcode
    elsif (scalar(@barcode_parts) == 6) {
        $case_id = join('-', @barcode_parts[0..3]);
        $s_case_id = $barcode_parts[3];
        $sample_id = join('-', @barcode_parts[0..4]);
        ($disease_code, $tissue_code_str, $nucleic_acid_code_str) = @barcode_parts[1,4,5];
    }
    else {
        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
            ": invalid sample ID/barcode $barcode\n";
    }
    my ($tissue_code, $xeno_cell_line_code, $tissue_ltr, $tissue_sort_code) =
        $tissue_code_str =~ /^(\d{2})(?:\.(\d+))?([A-Z])(?:\.(\d+))?$/;
    my $tissue_type = $tissue_code eq '01' ? 'Primary' :
                      $tissue_code eq '02' ? 'Recurrent' :
                      $tissue_code eq '03' ? 'Primary' :
                      $tissue_code eq '04' ? 'Recurrent' :
                      $tissue_code eq '05' ? 'Primary' :
                      # 06,07 are Metastatic and 08 is Post Neo-Adjuvant
                      # but all Primary for this purpose
                      $tissue_code eq '06' ? 'Primary' :
                      $tissue_code eq '07' ? 'Primary' :
                      $tissue_code eq '08' ? 'Primary' :
                      $tissue_code eq '09' ? 'Primary' :
                      $tissue_code eq '10' ? 'Normal' :
                      $tissue_code eq '11' ? 'Normal' :
                      $tissue_code eq '12' ? 'BuccalNormal' :
                      $tissue_code eq '13' ? 'EBVNormal' :
                      $tissue_code eq '14' ? 'Normal' :
                      $tissue_code eq '15' ? 'NormalFibroblast' :
                      $tissue_code eq '16' ? 'Normal' :
                      $tissue_code eq '17' ? 'Normal' :
                      # 18 is Post Neo-Adjuvant Adjacent Normal
                      # but Normal for this purpose
                      $tissue_code eq '18' ? 'Normal' :
                      $tissue_code eq '20' ? 'CellLineControl' :
                      $tissue_code eq '40' ? 'Recurrent' :
                      $tissue_code eq '41' ? 'Recurrent' :
                      $tissue_code eq '42' ? 'Recurrent' :
                      $tissue_code eq '50' ? 'CellLine' :
                      $tissue_code eq '60' ? 'Xenograft' :
                      $tissue_code eq '61' ? 'Xenograft' :
                      $tissue_code eq '99' ? 'Granulocyte' :
                      undef;
    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
        ": $barcode unknown tissue code $tissue_code\n" unless defined $tissue_type;
    my $tissue_name = $tissue_code eq '01' ? 'Solid Tumor' :
                      $tissue_code eq '02' ? 'Solid Tumor' :
                      $tissue_code eq '03' ? 'Peripheral Blood' :
                      $tissue_code eq '04' ? 'Bone Marrow' :
                      $tissue_code eq '06' ? 'Metastatic Tumor' :
                      $tissue_code eq '07' ? 'Metastatic Tumor' :
                      $tissue_code eq '08' ? 'Post-Neo Adjuvant Therapy Tumor' :
                      $tissue_code eq '09' ? 'Bone Marrow' :
                      $tissue_code eq '10' ? 'Peripheral Blood' :
                      $tissue_code eq '11' ? 'Tissue' :
                      $tissue_code eq '13' ? 'EBV Immortalized Normal' :
                      $tissue_code eq '14' ? 'Bone Marrow' :
                      $tissue_code eq '15' ? 'Bone Marrow' :
                      $tissue_code eq '20' ? 'Cell Line' :
                      $tissue_code eq '40' ? 'Peripheral Blood' :
                      $tissue_code eq '41' ? 'Bone Marrow' :
                      $tissue_code eq '42' ? 'Peripheral Blood' :
                      $tissue_code eq '50' ? 'Cell Line' :
                      $tissue_code eq '60' ? 'Xenograft' :
                      $tissue_code eq '61' ? 'Xenograft' :
                      undef;
    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
        ": $barcode unknown tissue code $tissue_code\n" unless defined $tissue_name;
    my $cgi_tissue_type = $tissue_type;
    # special fix for TARGET-10-PANKMB
    if ($case_id eq 'TARGET-10-PANKMB' and $tissue_type eq 'Primary') {
        $cgi_tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-10-PAKKCA
    elsif ($case_id eq 'TARGET-10-PAKKCA' and $tissue_type eq 'Primary') {
        $cgi_tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-30-PARKGJ
    elsif ($case_id eq 'TARGET-30-PARKGJ' and ($tissue_type eq 'Primary' or $tissue_type eq 'Normal')) {
        $cgi_tissue_type .= $barcode_parts[$#barcode_parts];
    }
    # special fix for TARGET-50-PAKJGM
    elsif ($case_id eq 'TARGET-50-PAKJGM' and $tissue_type eq 'Normal') {
        $cgi_tissue_type .= $barcode_parts[$#barcode_parts];
    }
    $cgi_tissue_type .= ( defined($xeno_cell_line_code) ? $xeno_cell_line_code : '' );
    my $nucleic_acid_code = substr($nucleic_acid_code_str, 0, 2);
    my $nucleic_acid_ltr = substr($nucleic_acid_code_str, -1);
    return {
        case_id => $case_id,
        s_case_id => $s_case_id,
        sample_id => $sample_id,
        disease_code => $disease_code,
        tissue_code => $tissue_code,
        tissue_ltr => $tissue_ltr,
        tissue_sort_code => $tissue_sort_code,
        tissue_type => $tissue_type,
        cgi_tissue_type => $cgi_tissue_type,
        tissue_name => $tissue_name,
        xeno_cell_line_code => $xeno_cell_line_code,
        nucleic_acid_code => $nucleic_acid_code,
        nucleic_acid_ltr => $nucleic_acid_ltr,
    };
}

sub get_ncit_disease {
    my ($disease_code) = @_;
    my $ncit_disease = $disease_code eq '00' ? 'Normal' :
                       $disease_code eq '01' ? 'Diffuse Large B-Cell Lymphoma' :
                       $disease_code eq '02' ? 'Lung Cancer' :
                       $disease_code eq '10' ? 'Acute Lymphoblastic Leukemia' :
                       $disease_code eq '15' ? 'Mixed Phenotype Acute Leukemia' :
                       $disease_code eq '20' ? 'Acute Myeloid Leukemia' :
                       $disease_code eq '21' ? 'Acute Myeloid Leukemia' :
                       $disease_code eq '30' ? 'Neuroblastoma' :
                       $disease_code eq '40' ? 'Osteosarcoma' :
                       $disease_code eq '41' ? 'Ewing Sarcoma' :
                       $disease_code eq '50' ? 'Kidney Wilms Tumor' :
                       $disease_code eq '51' ? 'Clear Cell Sarcoma of the Kidney' :
                       $disease_code eq '52' ? 'Rhabdoid Tumor of the Kidney' :
                       $disease_code eq '60' ? 'Ependymoma' :
                       $disease_code eq '61' ? 'Glioblastoma' :
                       $disease_code eq '62' ? 'Rhabdoid Tumor of the Kidney' :
                       $disease_code eq '63' ? 'Low Grade Glioma' :
                       $disease_code eq '64' ? 'Medulloblastoma' :
                       $disease_code eq '65' ? 'CNS Disease Other' :
                       $disease_code eq '70' ? 'Anaplastic Large Cell Lymphoma' :
                       $disease_code eq '71' ? 'Burkitt Lymphoma' :
                       $disease_code eq '80' ? 'Rhabdomyosarcoma' :
                       $disease_code eq '81' ? 'Non-Rhabdomyosarcoma Soft Tissue Sarcoma' :
                       # special disease codes
                       $disease_code eq '100' ? 'Diffuse Large B-Cell Lymphoma' :
                       $disease_code eq '101' ? 'Follicular Lymphoma' :
                       undef;
    die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
        ": unknown disease code $disease_code\n" unless defined $ncit_disease;
    return $ncit_disease;
}

sub get_ncit_disease_state {
    my ($ncit_disease, $disease_code, $tissue_code) = @_;
    my $ncit_disease_state = $tissue_code eq '01' ? $ncit_disease :
                             $tissue_code eq '02' ? "Recurrent $ncit_disease" :
                             $tissue_code eq '03' ? $ncit_disease :
                             $tissue_code eq '04' ? "Recurrent $ncit_disease" :
                             $tissue_code eq '05' ? $ncit_disease :
                             $tissue_code eq '06' ? "Metastatic $ncit_disease" :
                             $tissue_code eq '07' ? $ncit_disease :
                             $tissue_code eq '08' ? $ncit_disease :
                             $tissue_code eq '09' ? $ncit_disease :
                             $tissue_code eq '10' ? $ncit_disease :
                             $tissue_code eq '11' ? $ncit_disease :
                             $tissue_code eq '12' ? $ncit_disease :
                             $tissue_code eq '13' ? $ncit_disease :
                             $tissue_code eq '14' ? $ncit_disease :
                             $tissue_code eq '15' ? $ncit_disease :
                             $tissue_code eq '16' ? $ncit_disease :
                             $tissue_code eq '17' ? $ncit_disease :
                             $tissue_code eq '18' ? $ncit_disease :
                             $tissue_code eq '20' ? $ncit_disease :
                             $tissue_code eq '40' ? "Recurrent $ncit_disease" :
                             $tissue_code eq '41' ? $ncit_disease :
                             $tissue_code eq '42' ? $ncit_disease :
                             $tissue_code eq '50' ? $ncit_disease :
                             $tissue_code eq '60' ? $ncit_disease :
                             $tissue_code eq '61' ? $ncit_disease :
                             $tissue_code eq '99' ? $ncit_disease :
                             # special exceptions (using disease_code)
                             $disease_code eq '100' ? '' :
                             $disease_code eq '101' ? '' :
                             undef;
    die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
        ": unknown tissue code $tissue_code\n" unless defined $ncit_disease_state;
    return $ncit_disease_state;
}

sub get_ncit_organism_part {
    my ($disease_code, $tissue_code) = @_;
    my $ncit_organism_part = $tissue_code eq '01' ? 'Solid Tumor' :
                             $tissue_code eq '02' ? 'Solid Tumor' :
                             $tissue_code eq '03' ? 'Peripheral Blood' :
                             $tissue_code eq '04' ? 'Bone Marrow' :
                             $tissue_code eq '05' ? 'Primary Tumor' :
                             $tissue_code eq '06' ? 'Metastatic Tumor' :
                             $tissue_code eq '07' ? 'Metastatic Tumor' :
                             $tissue_code eq '08' ? 'Primary Tumor' :
                             $tissue_code eq '09' ? 'Bone Marrow' :
                             $tissue_code eq '10' ? 'Peripheral Blood' :
                             $tissue_code eq '11' ? 'Normal Tissue' :
                             $tissue_code eq '12' ? 'Buccal Mucosa' :
                             $tissue_code eq '13' ? 'Lymphocyte' :
                             $tissue_code eq '14' ? 'Bone Marrow' :
                             $tissue_code eq '15' ? 'Bone Marrow' :
                             $tissue_code eq '16' ? 'Bone Marrow' :
                             $tissue_code eq '17' ? 'Lymphoid Tissue' :
                             $tissue_code eq '18' ? 'Adjacent Normal Tissue' :
                             $tissue_code eq '20' ? 'Cell Line' :
                             $tissue_code eq '40' ? 'Peripheral Blood' :
                             $tissue_code eq '41' ? 'Bone Marrow' :
                             $tissue_code eq '42' ? 'Peripheral Blood' :
                             $tissue_code eq '50' ? 'Cell Line' :
                             $tissue_code eq '60' ? 'Xenograft' :
                             $tissue_code eq '61' ? 'Xenograft' :
                             $tissue_code eq '99' ? 'Granulocyte' :
                             # special exceptions (using disease code)
                             $disease_code eq '100' ? '' :
                             $disease_code eq '101' ? '' :
                             undef;
    die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
        ": unknown tissue code $tissue_code\n" unless defined $ncit_organism_part;
    return $ncit_organism_part;
}

# sort by file path (file column idx 1)
sub manifest_by_file_path ($$) {
    my ($a, $b) = @_;
    my $a_file_path = (split(' ', $a, 2))[1];
    my $b_file_path = (split(' ', $b, 2))[1];
    my @a_path_parts = File::Spec->splitdir($a_file_path);
    my @b_path_parts = File::Spec->splitdir($b_file_path);
    # sort top-level files last
    if (
        $#a_path_parts != 0 and
        $#b_path_parts == 0
    ) {
        return -1;
    }
    elsif (
        $#a_path_parts == 0 and
        $#b_path_parts != 0
    ) {
        return 1;
    }
    for my $i (
        0 .. max($#a_path_parts, $#b_path_parts)
    ) {
        # debugging
        #print join(',', map { $_ eq $a_path_parts[$i] ? colored($_, 'red') : $_ } @a_path_parts), "\n",
        #      join(',', map { $_ eq $b_path_parts[$i] ? colored($_, 'red') : $_ } @b_path_parts);
        #<STDIN>;
        return -1 if $i > $#a_path_parts;
        return  1 if $i > $#b_path_parts;
        # do standard ls sorting instead of natural sorting
        #return mkkey_natural(lc($a_path_parts[$i])) cmp mkkey_natural(lc($b_path_parts[$i]))
        #    if mkkey_natural(lc($a_path_parts[$i])) cmp mkkey_natural(lc($b_path_parts[$i]));
        return lc($a_path_parts[$i]) cmp lc($b_path_parts[$i])
            if lc($a_path_parts[$i]) cmp lc($b_path_parts[$i]);
    }
    return $#a_path_parts <=> $#b_path_parts;
}

1;
