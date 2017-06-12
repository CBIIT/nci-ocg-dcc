#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use sigtrap qw( handler sig_handler normal-signals error-signals ALRM );
use Cwd qw( cwd realpath );
use File::Basename qw( fileparse dirname );
use File::Find;
use File::Path 2.11 qw( make_path remove_tree );
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any all first none sum uniq );
use List::MoreUtils qw( firstidx );
use NCI::OCGDCC::Config qw( :all );
use NCI::OCGDCC::Utils qw( load_configs get_barcode_info );
use Path::Iterator::Rule;
use Pod::Usage qw( pod2usage );
use Spreadsheet::Read qw( ReadData cellrow );
use Sort::Key::Natural qw( natsort );
use Storable qw( lock_nstore lock_retrieve );
use Sort::Key::Natural qw( natsort );
use Term::ANSIColor;
use Data::Dumper;

sub sig_handler {
    die "Caught signal, exiting\n";
}

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

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
    cgi
    common
    variant_analysis
));
my @program_names = @{$config_hashref->{'common'}->{'program_names'}};
my %program_project_names = %{$config_hashref->{'common'}->{'program_project_names'}};
my %program_project_names_w_subprojects = %{$config_hashref->{'common'}->{'program_project_names_w_subprojects'}};
my @programs_w_data_types = @{$config_hashref->{'common'}->{'programs_w_data_types'}};
my @data_types_w_data_levels = @{$config_hashref->{'common'}->{'data_types_w_data_levels'}};
my $cgi_dir_name = $config_hashref->{'cgi'}->{'dir_name'};
my @cgi_analysis_dir_names = @{$config_hashref->{'cgi'}->{'analysis_dir_names'}};
# use variant_analysis data types and data level dir names (not common)
my @data_types = @{$config_hashref->{'variant_analysis'}->{'data_types'}};
my @data_level_dir_names = @{$config_hashref->{'variant_analysis'}->{'data_level_dir_names'}};
my %maf_config = %{$config_hashref->{'variant_analysis'}->{'maf_config'}};
my @ver_data_file_types = @{$config_hashref->{'variant_analysis'}->{'ver_data_file_types'}};
my %parse_files = %{$config_hashref->{'variant_analysis'}->{'parse_files'}};
my $count_ratio_format = $config_hashref->{'variant_analysis'}->{'count_ratio_format'};
my $maf_sep_char = $config_hashref->{'variant_analysis'}->{'maf_sep_char'};
my %debug_types = map { $_ => 1 } qw(
    all
    params
    conf
    cgi
    maf_parse
    maf_xls
    ver_data
    ver_step
);
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
    cases
);

my $output_dir = cwd();
my $cache_dir = "$CACHE_DIR/verified_mafs";
my $rebuild_cache = 0;
my $no_cache = 0;
my $no_unverified = 0;
my $conserve_memory = 0;
my $use_cgi_filtered_mafs = 0;
my $use_dbm = 0;
my $verbose = 0;
my @debug = ();
GetOptions(
    'output-dir=s' => \$output_dir,
    'cache-dir=s' => \$cache_dir,
    'rebuild-cache' => \$rebuild_cache,
    'no-cache' => \$no_cache,
    'no-unverified' => \$no_unverified,
    'conserve-memory' => \$conserve_memory,
    'use-cgi-filtered-mafs' => \$use_cgi_filtered_mafs,
    'use-dbm' => \$use_dbm,
    'verbose' => \$verbose,
    'debug:s' => \@debug,
) || pod2usage(-verbose => 0);
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/;
        my (@valid_user_params, @invalid_user_params, @valid_choices);
        my @user_params = split(',', $ARGV[$i]);
        if ($param_groups[$i] eq 'programs') {
            for my $program_name (@program_names) {
                push @valid_user_params, $program_name if any { m/^$program_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @program_names;
            }
            @valid_choices = @program_names;
        }
        elsif ($param_groups[$i] eq 'projects') {
            my @program_projects = uniq(
                defined($user_params{programs})
                    ? map { @{$program_project_names{$_}} } @{$user_params{programs}}
                    : map { @{$program_project_names{$_}} } @program_names
            );
            for my $project_name (@program_projects) {
                push @valid_user_params, $project_name if any { m/^$project_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @program_projects;
            }
            @valid_choices = @program_projects;
        }
        elsif ($param_groups[$i] eq 'data_types') {
            for my $user_param (@user_params) {
                $user_param = 'mRNA-seq' if $user_param =~ /^RNA-seq$/i;
            }
            for my $data_type (@data_types) {
                push @valid_user_params, $data_type if any { m/^$data_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_types;
            }
            @valid_choices = @data_types;
        }
        else {
            @valid_user_params = @user_params;
        }
        if (@invalid_user_params) {
            (my $type = $param_groups[$i]) =~ s/s$//;
            $type =~ s/_/ /g;
            pod2usage(
                -message =>
                    "Invalid $type" . ( scalar(@invalid_user_params) > 1 ? 's' : '' ) . ': ' .
                    join(', ', @invalid_user_params) . "\n" .
                    'Choose from: ' . join(', ', @valid_choices),
                -verbose => 0,
            );
        }
        $user_params{$param_groups[$i]} = \@valid_user_params;
    }
}
my %debug = map { $_ => 1 } split(',', join(',', map { lc($_) || 'all' } @debug));
for my $debug_type (natsort keys %debug) {
    if (!$debug_types{$debug_type}) {
        pod2usage(
            -message => "Invalid debug type: $debug_type\nAllowed debug types: " . join(', ', sort keys %debug_types), 
            -verbose => 0,
        );
    }
}
if ($debug{all} or $debug{params}) {
    print STDERR 
        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
        ": \%user_params:\n", Dumper(\%user_params);
}
if (!-d $cache_dir) {
    make_path($cache_dir, { chmod => 0700 }) 
        or die "ERROR: could not create $cache_dir: $!\n";
}
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    PROJECT_NAME: for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
        my ($disease_proj, $subproject);
        if (any { $project_name eq $_ } @{$program_project_names_w_subprojects{$program_name}}) {
            ($disease_proj, $subproject) = split /-/, $project_name, 2;
        }
        else {
            $disease_proj = $project_name;
        }
        my $project_dir_path_part = $disease_proj;
        if (defined($subproject)) {
            $project_dir_path_part = "$project_dir_path_part/$subproject";
        }
        # programs with data types
        if (any { $program_name eq $_ } @programs_w_data_types) {
            DATA_TYPE: for my $data_type (@data_types) {
                next if defined($user_params{data_types}) and none { $data_type eq $_ } @{$user_params{data_types}};
                (my $data_type_dir_name = $data_type) =~ s/-Seq$/-seq/i;
                my $data_type_dir = "/local/ocg-dcc/data/\U$program_name\E/$project_dir_path_part/$data_type_dir_name";
                next unless -d $data_type_dir;
                opendir(my $data_type_dh, $data_type_dir)
                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_dir: $!";
                my @data_type_sub_dir_names = grep { -d "$data_type_dir/$_" and !m/^\./ } readdir($data_type_dh);
                closedir($data_type_dh);
                my @datasets;
                if (all { m/^(current|old)$/ } @data_type_sub_dir_names) {
                    push @datasets, '';
                }
                elsif (none { m/^(current|old)$/ } @data_type_sub_dir_names) {
                    for my $data_type_sub_dir_name (@data_type_sub_dir_names) {
                        my $data_type_sub_dir = "$data_type_dir/$data_type_sub_dir_name";
                        opendir(my $data_type_sub_dh, $data_type_sub_dir)
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_sub_dir: $!";
                        my @sub_dir_names = grep { -d "$data_type_sub_dir/$_" and !m/^\./ } readdir($data_type_sub_dh);
                        closedir($data_type_sub_dh);
                        if (all { m/^(current|old)$/ } @sub_dir_names) {
                            push @datasets, $data_type_sub_dir_name;
                        }
                        else {
                            warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                 ": $data_type_dir subdirectory structure is invalid\n";
                            next DATA_TYPE;
                        }
                    }
                }
                else {
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                         ": $data_type_dir subdirectory structure is invalid\n";
                    next DATA_TYPE;
                }
                for my $dataset (@datasets) {
                    next if defined($user_params{data_sets}) and none { $dataset eq $_ } @{$user_params{data_sets}};
                    my $dataset_dir = $data_type_dir . ( $dataset eq '' ? $dataset : "/$dataset" ) . '/current';
                    next unless -d $dataset_dir;
                    for my $data_level_dir_name (@data_level_dir_names) {
                        my $data_level_dir = "$dataset_dir/$data_level_dir_name";
                        next unless -d $data_level_dir;
                        my $dataset_output_dir = "$output_dir/$project_name/$data_type";
                        # re-init output dir if exists
                        if ( -d $dataset_output_dir and
                            !-z $dataset_output_dir) {
                            remove_tree($dataset_output_dir, { keep_root => 1 }) or die "ERROR: could not re-init $dataset_output_dir: $!";
                        }
                        my $tcs_data_dir = "/local/ocg-dcc/data/\U$program_name\E/$project_dir_path_part/targeted_capture_sequencing" .
                                           ( $dataset eq '' ? $dataset : "/$dataset" ) .
                                           "/current/$data_level_dir_name";
                        print "Found TCS $tcs_data_dir\n" if -d $tcs_data_dir;
                        my $rna_data_dir = "/local/ocg-dcc/data/\U$program_name\E/$project_dir_path_part/mRNA-seq" .
                                           ( $dataset eq '' ? $dataset : "/$dataset" ) .
                                           "/current/$data_level_dir_name";
                        print "Found RNA $rna_data_dir\n" if -d $rna_data_dir;
                        if ($data_type eq 'WGS') {
                            # CGI WGS
                            if (-d "$dataset_dir/$cgi_dir_name") {
                                my $cgi_dataset_dir = realpath("$dataset_dir/$cgi_dir_name");
                                my @cgi_data_dirs;
                                for my $dir_name (@cgi_analysis_dir_names) {
                                    my $cgi_data_dir = "$cgi_dataset_dir/$dir_name";
                                    push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
                                }
                                if ($debug{all} or $debug{cgi}) {
                                    print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs);
                                }
                                my $maf_type = 'CGI';
                                my $cgi_somatic_maf_regexp = $use_cgi_filtered_mafs
                                    ? qr/^somatic_filtered_data_only$/i
                                    : qr/^somaticVcfBeta.+?somatic_maf.*?\.txt$/i;
                                my %maf_out_file_names_by_type;
                                print "Scanning $cgi_dataset_dir\n";
                                find({
                                    follow => 1,
                                    wanted => sub {
                                        # directories
                                        if (-d) {
                                            my $dir_name = $_;
                                            # skip "old_data" subdirectory trees
                                            # skip "VCF_files_without_FET" subdirectory trees
                                            if ($dir_name =~ /(old_data|VCF_files_without_FET)/i) {
                                                #print "Skipping $File::Find::name\n" if $verbose;
                                                $File::Find::prune = 1;
                                                return;
                                            }
                                            # TARGET case-named directories (with possible CGI numeric extension)
                                            elsif ($dir_name =~ /^$OCG_CGI_CASE_DIR_REGEXP$/) {
                                                my ($case_id) = $dir_name =~ /^($OCG_CASE_REGEXP)/;
                                                my @case_id_parts = split('-', $case_id);
                                                my $s_case_id = $case_id_parts[$#case_id_parts];
                                                # if analyzing specific cases prune tree if not in list
                                                if (defined $user_params{cases} and !exists $user_params{cases}{uc($s_case_id)}) {
                                                    $File::Find::prune = 1;
                                                    return;
                                                }
                                            }
                                            # TARGET barcode-named directories
                                            #elsif ($dir_name =~ /^$OCG_BARCODE_REGEXP$/) {
                                            #    
                                            #}
                                        }
                                        # files
                                        elsif (-f) {
                                            my $file_name = $_;
                                            # CGI somatic MAFs
                                            if ($file_name =~ /$cgi_somatic_maf_regexp/) {
                                                my @dir_parts = File::Spec->splitdir($File::Find::dir);
                                                my ($case_dir_name) = grep { m/^$OCG_CGI_CASE_DIR_REGEXP$/ } @dir_parts;
                                                my $case_exp_dir = File::Spec->catdir(@dir_parts[0 .. $#dir_parts - 2]);
                                                my ($disease_barcode) = grep { m/^$OCG_BARCODE_REGEXP$/ } @dir_parts;
                                                # determine comparator
                                                if ($dir_parts[$#dir_parts] ne 'ASM' or
                                                    $dir_parts[$#dir_parts - 2] ne 'EXP') {
                                                    die "ERROR: invalid CGI sample directory path: $File::Find::dir";
                                                }
                                                if ($debug{all} or $debug{cgi}) {
                                                    print STDERR "\$case_exp_dir:\n$case_exp_dir\n";
                                                }
                                                my @other_sample_dirs = 
                                                    grep {
                                                        -d and 
                                                        m/^$case_exp_dir\/$OCG_BARCODE_REGEXP$/ and 
                                                        $_ ne "$case_exp_dir/$dir_parts[$#dir_parts - 1]"
                                                    } glob("$case_exp_dir/*");
                                                if ($debug{all} or $debug{cgi}) {
                                                    print STDERR "\@other_sample_dirs:\n", Dumper(\@other_sample_dirs);
                                                }
                                                my ($normal_barcode, $normal_sample_dir);
                                                if (scalar(@other_sample_dirs) > 1) {
                                                    my @other_normal_sample_dirs;
                                                    for my $other_sample_dir (@other_sample_dirs) {
                                                        my @other_sample_dir_parts = File::Spec->splitdir($other_sample_dir);
                                                        my $barcode = $other_sample_dir_parts[$#other_sample_dir_parts];
                                                        if (get_barcode_info($barcode)->{tissue_type} =~ /Normal/) {
                                                            push @other_normal_sample_dirs, $other_sample_dir;
                                                        }
                                                    }
                                                    if (scalar(@other_normal_sample_dirs) == 1) {
                                                        $normal_sample_dir = $other_normal_sample_dirs[0];
                                                        my @normal_sample_dir_parts = File::Spec->splitdir($normal_sample_dir);
                                                        $normal_barcode = $normal_sample_dir_parts[$#normal_sample_dir_parts];
                                                    }
                                                    else {
                                                        die "ERROR: could not determine comparator sample directory in $case_exp_dir";
                                                    }
                                                }
                                                elsif (scalar(@other_sample_dirs) == 1) {
                                                    $normal_sample_dir = $other_sample_dirs[0];
                                                    my @normal_sample_dir_parts = File::Spec->splitdir($normal_sample_dir);
                                                    $normal_barcode = $normal_sample_dir_parts[$#normal_sample_dir_parts];
                                                }
                                                else {
                                                    die "ERROR: sample directories missing in $case_exp_dir";
                                                }
                                                if ($debug{all} or $debug{cgi}) {
                                                    print STDERR "\$normal_sample_dir:\n$normal_sample_dir\n";
                                                }
                                                if (!-d "$normal_sample_dir/ASM") {
                                                    die "ERROR: invalid sample data directory: $normal_sample_dir";
                                                }
                                                if (
                                                    grep { -f and m/^$normal_sample_dir\/ASM\/somaticVcfBeta/i }
                                                    glob("$normal_sample_dir/ASM/*")
                                                ) {
                                                    die "ERROR: comparator sample data directory contains somatic data: $normal_sample_dir/ASM";
                                                }
                                                if ($debug{all} or $debug{cgi}) {
                                                    print STDERR "\$disease_barcode: $disease_barcode\n\$normal_barcode: $normal_barcode\n";
                                                }
                                                my $ver_data_hashref = get_verification_data(
                                                    $disease_barcode, $normal_barcode,
                                                    $tcs_data_dir, $rna_data_dir,
                                                );
                                                my (%maf_out_data_by_type, @maf_col_headers, %maf_col_idx_by_name, 
                                                    @splice_col_offsets, $maf_num_orig_cols);
                                                print "Parsing ", File::Spec->abs2rel($File::Find::name, $cgi_dataset_dir), "\n" if $verbose;
                                                open(my $maf_in_fh, '<', $File::Find::name)
                                                    or die "ERROR: could not open $File::Find::name";
                                                while (<$maf_in_fh>) {
                                                    s/\s+$//;
                                                    if (!m/^#/ and !@maf_col_headers) {
                                                        @maf_col_headers = split /\t/;
                                                        for (@maf_col_headers) {
                                                            s/^\s+//;
                                                            s/\s+$//;
                                                        }
                                                        $maf_num_orig_cols = scalar(@maf_col_headers);
                                                        # insert new columns before tumor_ref_count
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_ref_allele'};
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_tumor_allele_1'};
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_tumor_allele_2'};
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_norm_allele_1'};
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_norm_allele_2'};
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_vcf_filter'};
                                                        # insert tumor_var_ratio before norm_ref_count
                                                        push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'norm_ref_count'} } @maf_col_headers;
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'tumor_var_ratio'};
                                                        # insert norm_var_ratio at end
                                                        push @splice_col_offsets, scalar(@maf_col_headers);
                                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'norm_var_ratio'};
                                                        %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                                        if ($debug{all} or $debug{maf_parse}) {
                                                            print STDERR "\@maf_col_headers:\n", Dumper(\@maf_col_headers), "\n",
                                                                         "\%maf_col_idx_by_name:\n", Dumper(\%maf_col_idx_by_name);
                                                        }
                                                    }
                                                    elsif (@maf_col_headers) {
                                                        my @maf_row_data = split /\t/;
                                                        for (@maf_row_data) {
                                                            s/^\s+//;
                                                            s/\s+$//;
                                                        }
                                                        # make sure data matrix is rectangular by appending blank missing fields if necessary
                                                        if (scalar(@maf_row_data) < $maf_num_orig_cols) {
                                                            push @maf_row_data, ($maf_config{$maf_type}{'blank_val'}) x ( $maf_num_orig_cols - scalar(@maf_row_data) );
                                                        }
                                                        elsif (scalar(@maf_row_data) > $maf_num_orig_cols) {
                                                            die "ERROR: ", scalar(@maf_row_data), " data fields more than ",
                                                                           $maf_num_orig_cols, " column headers at line $.";
                                                        }
                                                        # insert new blank data fields
                                                        for my $splice_col_offset (@splice_col_offsets) {
                                                            splice @maf_row_data, $splice_col_offset, 0, ($maf_config{$maf_type}{'blank_val'}) x 1;
                                                        }
                                                        # skip any mutations without a gene symbol
                                                        #next unless defined $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'gene_symbol'}}] and
                                                        #                    $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'gene_symbol'}}] ne $maf_config{$maf_type}{'blank_val'};
                                                        # skip any INTRON/UTR/UTR3/UTR5/TSS-UPSTREAM mutations
                                                        #next unless defined $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'variant_class'}}] and
                                                        #                    $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'variant_class'}}] ne $maf_config{$maf_type}{'blank_val'};
                                                        #my $valid_variant_classification;
                                                        #for my $variant_classification (split /[|,]/, $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'variant_class'}}]) {
                                                        #    $variant_classification =~ s/\s+//g;
                                                        #    if ($variant_classification !~ /^(INTRON|UTR(3|5)?|TSS-UPSTREAM)$/i) {
                                                        #        $valid_variant_classification++;
                                                        #        last;
                                                        #    }
                                                        #}
                                                        #next unless $valid_variant_classification;
                                                        if (verify_maf_line($maf_type, \@maf_row_data, \%maf_col_idx_by_name, $ver_data_hashref)) {
                                                            push @{$maf_out_data_by_type{verified}}, \@maf_row_data;
                                                        }
                                                        elsif (!$no_unverified) {
                                                            push @{$maf_out_data_by_type{unverified}}, \@maf_row_data;
                                                        }
                                                    }
                                                    else {
                                                        die "ERROR: invalid MAF line $.";
                                                    }
                                                }
                                                close($maf_in_fh);
                                                my $case_id = get_barcode_info($disease_barcode)->{case_id};
                                                if ($case_dir_name =~ /(?:-|_)(\d+)$/) {
                                                    $case_id .= "-$1";
                                                }
                                                my $disease_tissue_type = get_barcode_info($disease_barcode)->{tissue_type};
                                                my $normal_tissue_type = get_barcode_info($normal_barcode)->{tissue_type};
                                                if (!-d $dataset_output_dir) {
                                                    make_path($dataset_output_dir, { chmod => 0700 })
                                                        or die "ERROR: could not create $dataset_output_dir: $!\n";
                                                }
                                                for my $type (qw(verified unverified)) {
                                                    next if $type eq 'unverified' and $no_unverified;
                                                    if (defined $maf_out_data_by_type{$type}) {
                                                        my $maf_out_file_name = 
                                                            "${type}Somatic" . 
                                                            ($use_cgi_filtered_mafs ? 'Filtered' : '') .
                                                            "Maf_${case_id}_${normal_tissue_type}Vs${disease_tissue_type}.maf.txt";
                                                        if (!-f "$dataset_output_dir/$maf_out_file_name") {
                                                            push @{$maf_out_file_names_by_type{$type}}, $maf_out_file_name;
                                                            if ($verbose) {
                                                                print "Writing $maf_out_file_name\n";
                                                            }
                                                            open(my $maf_out_fh, '>', "$dataset_output_dir/$maf_out_file_name")
                                                                or die "ERROR: could not create $dataset_output_dir/$maf_out_file_name: $!";
                                                            print $maf_out_fh join("\t", @maf_col_headers), "\n";
                                                            for my $data_row_arrayref (@{$maf_out_data_by_type{$type}}) {
                                                                print $maf_out_fh join("\t", @{$data_row_arrayref}), "\n";
                                                            }
                                                            close($maf_out_fh);
                                                        }
                                                        else {
                                                            die "ERROR: $dataset_output_dir/$maf_out_file_name already exists";
                                                        }
                                                    }
                                                    elsif ($verbose) {
                                                        print "No $type data\n";
                                                    }
                                                }
                                            }
                                        }
                                    },
                                }, @cgi_data_dirs);
                                my %merged_maf_out_data_by_type;
                                for my $type (qw(verified unverified)) {
                                    next if $type eq 'unverified' and $no_unverified;
                                    if (defined $maf_out_file_names_by_type{$type}) {
                                        my $merged_maf_out_file_name = 
                                            "${type}Somatic" . 
                                            ($use_cgi_filtered_mafs ? 'Filtered' : '') .
                                            "Maf_${program_name}_${project_name}_${data_type}_${cgi_dir_name}.maf.txt";
                                        if ($verbose and ($type eq 'verified' or $use_cgi_filtered_mafs)) {
                                            print "Generating $merged_maf_out_file_name\n";
                                        }
                                        my (@maf_col_headers, %maf_col_idx_by_name);
                                        for my $maf_file_name (@{$maf_out_file_names_by_type{$type}}) {
                                            # case ID is 2nd term in file name (above)
                                            my $case_id = (split('_', $maf_file_name))[1];
                                            open(my $maf_in_fh, '<', "$dataset_output_dir/$maf_file_name")
                                                or die "ERROR: could not open $dataset_output_dir/$maf_file_name";
                                            if (!@maf_col_headers) {
                                                chomp(@maf_col_headers = split /\t/, <$maf_in_fh>);
                                                %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                            }
                                            else {
                                                <$maf_in_fh>;
                                            }
                                            while (<$maf_in_fh>) {
                                                chomp;
                                                my @maf_row_data = split /\t/;
                                                if ($type eq 'verified') {
                                                    my $tumor_barcode  = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'tumor_barcode'}}];
                                                    my $normal_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'norm_barcode'}}];
                                                    my $chr            = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'chr'}}];
                                                    my $start_pos      = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'pos'}}];
                                                    my $end_pos        = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'end_pos'}}];
                                                    if (!exists $merged_maf_out_data_by_type{$type}{"$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"}) {
                                                        $merged_maf_out_data_by_type{$type}{"$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"} = \@maf_row_data;
                                                    }
                                                    # handle duplicate CGI mutation data
                                                    else {
                                                        my @new_ver_methods = split(
                                                            $maf_sep_char, 
                                                            $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'ver_method'}}]
                                                        );
                                                        my @existing_ver_methods = split(
                                                            $maf_sep_char,
                                                            $merged_maf_out_data_by_type{$type}{
                                                                "$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"
                                                            }[$maf_col_idx_by_name{$maf_config{$maf_type}{'ver_method'}}]
                                                        );
                                                        # replace with new row if has more verification methods or if same 
                                                        # replace with new row if from CGI case directory with extension (newer)
                                                        if (
                                                            (
                                                                scalar(@new_ver_methods) > scalar(@existing_ver_methods)
                                                            ) or
                                                            (
                                                                scalar(@new_ver_methods) == scalar(@existing_ver_methods) and
                                                                $case_id =~ /-\d+$/
                                                            )
                                                        ) {
                                                            $merged_maf_out_data_by_type{$type}{"$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"} = \@maf_row_data;
                                                        }
                                                    }
                                                }
                                                elsif ($use_cgi_filtered_mafs) {
                                                    push @{$merged_maf_out_data_by_type{$type}}, \@maf_row_data;
                                                }
                                            }
                                            close($maf_in_fh);
                                            my $merged_maf_out_fh;
                                            if ($type eq 'verified' or $use_cgi_filtered_mafs) {
                                                open($merged_maf_out_fh, '>', "$dataset_output_dir/$merged_maf_out_file_name")
                                                    or die "ERROR: could not create $dataset_output_dir/$merged_maf_out_file_name: $!";
                                                print $merged_maf_out_fh join("\t", @maf_col_headers), "\n";
                                            }
                                            if ($type eq 'verified') {
                                                for my $maf_key (natsort keys %{$merged_maf_out_data_by_type{$type}}) {
                                                    print $merged_maf_out_fh join("\t", @{$merged_maf_out_data_by_type{$type}{$maf_key}}), "\n";
                                                }
                                            }
                                            elsif ($use_cgi_filtered_mafs) {
                                                for my $data_row_arrayref (@{$merged_maf_out_data_by_type{$type}}) {
                                                    print $merged_maf_out_fh join("\t", @{$data_row_arrayref}), "\n";
                                                }
                                            }
                                            close($merged_maf_out_fh) if defined $merged_maf_out_fh;
                                        }
                                    }
                                }
                            }
                            # BCCA WGS
                            else {

                            }
                        }
                        # WXS
                        elsif ($data_type eq 'WXS') {
                            my %maf_out_file_names_by_type;
                            print "Scanning $dataset_dir/$data_level_dir_name\n";
                            find({
                                follow => 1,
                                wanted => sub {
                                    # files only
                                    return unless -f;
                                    my $file_name = $_;
                                    if (any { $file_name eq $_ } @{$parse_files{$program_name}{$project_name}{$data_type}{$data_level_dir_name}}) {
                                        my $maf_type = 'BCM';
                                        my ($ver_data_hashref, %maf_out_data_by_type, @maf_col_headers, 
                                            %maf_col_idx_by_name, @splice_col_offsets, $maf_num_orig_cols);
                                        print "Parsing ", File::Spec->abs2rel($File::Find::name, "$dataset_dir/$data_level_dir_name"), "\n" if $verbose;
                                        # txt maf
                                        if ($file_name =~ /\.txt$/i) {
                                            open(my $maf_in_fh, '<', $File::Find::name)
                                                or die "ERROR: could not open $File::Find::name";
                                            while (<$maf_in_fh>) {
                                                s/\s+$//;
                                                if (!m/^#/ and !@maf_col_headers) {
                                                    @maf_col_headers = split /\t/;
                                                    for (@maf_col_headers) {
                                                        s/^\s+//;
                                                        s/\s+$//;
                                                    }
                                                    $maf_num_orig_cols = scalar(@maf_col_headers);
                                                    # insert ver_ref_allele column before ver_tumor_allele_1 column
                                                    push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'ver_tumor_allele_1'} } @maf_col_headers;
                                                    splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_ref_allele'};
                                                    # insert ver_vcf_filter column before ver_status column
                                                    push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'ver_status'} } @maf_col_headers;
                                                    splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_vcf_filter'};
                                                    # insert tumor_ref_count column before tumor_var_count column
                                                    push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_var_count'} } @maf_col_headers;
                                                    splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'tumor_ref_count'};
                                                    # insert norm_ref_count column before norm_var_count column
                                                    push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'norm_var_count'} } @maf_col_headers;
                                                    splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'norm_ref_count'};
                                                    %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                                    if ($debug{all} or $debug{maf_parse}) {
                                                        print STDERR "\@maf_col_headers:\n", Dumper(\@maf_col_headers), "\n",
                                                                     "\%maf_col_idx_by_name:\n", Dumper(\%maf_col_idx_by_name);
                                                    }
                                                }
                                                elsif (@maf_col_headers) {
                                                    my @maf_row_data = split /\t/;
                                                    for (@maf_row_data) {
                                                        s/^\s+//;
                                                        s/\s+$//;
                                                    }
                                                    # make sure data matrix is rectangular by adding blank missing fields if necessary
                                                    if (scalar(@maf_row_data) < $maf_num_orig_cols) {
                                                        push @maf_row_data, ($maf_config{$maf_type}{'blank_val'}) x ( $maf_num_orig_cols - scalar(@maf_row_data) );
                                                    }
                                                    elsif (scalar(@maf_row_data) > $maf_num_orig_cols) {
                                                        die "ERROR: ", scalar(@maf_row_data), " data fields more than ",
                                                                       $maf_num_orig_cols, " column headers at line $.";
                                                    }
                                                    # insert new blank data fields
                                                    for my $splice_col_offset (@splice_col_offsets) {
                                                        splice @maf_row_data, $splice_col_offset, 0, ($maf_config{$maf_type}{'blank_val'}) x 1;
                                                    }
                                                    my $disease_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'tumor_barcode'}}];
                                                    my $normal_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'norm_barcode'}}];
                                                    # if analyzing specific cases skip case if not in list
                                                    if (defined $user_params{cases} and 
                                                       !exists $user_params{cases}{uc(get_barcode_info($disease_barcode)->{s_case_id})}) {
                                                        next;
                                                    }
                                                    if (!defined $ver_data_hashref or 
                                                        $disease_barcode ne $ver_data_hashref->{disease_barcode} or
                                                        $normal_barcode ne $ver_data_hashref->{normal_barcode}) {
                                                        # free up memory
                                                        $ver_data_hashref = undef;
                                                        $ver_data_hashref = get_verification_data(
                                                            $disease_barcode, $normal_barcode,
                                                            $tcs_data_dir, $rna_data_dir,
                                                        );
                                                    }
                                                    if (verify_maf_line($maf_type, \@maf_row_data, \%maf_col_idx_by_name, $ver_data_hashref)) {
                                                        push @{$maf_out_data_by_type{verified}}, \@maf_row_data;
                                                    }
                                                    else {
                                                        push @{$maf_out_data_by_type{unverified}}, \@maf_row_data;
                                                    }
                                                }
                                                else {
                                                    die "ERROR: invalid MAF line $.";
                                                }
                                            }
                                            close($maf_in_fh);
                                        }
                                        # xls/xlsx maf
                                        elsif ($file_name =~ /\.xlsx?$/i) {
                                            my $maf_workbook = ReadData(
                                                $File::Find::name, 
                                                cells => 0, attr => 0, strip => 3,
                                            ) or die "ERROR: could not open $File::Find::name: $!";
                                            if ($maf_workbook->[0]->{sheets} != 1) {
                                                die "ERROR: xls/xlsx data file doesn't have one worksheet";
                                            }
                                            if ($debug{all} or $debug{maf_xls}) {
                                                print STDERR "\$maf_workbook:\n", Dumper($maf_workbook);
                                            }
                                            my $maf_sheet = $maf_workbook->[$maf_workbook->[0]->{sheets}];
                                            # Spreadsheet::Read row/col cell numbers start at 1
                                            @maf_col_headers = cellrow($maf_sheet, 1);
                                            $maf_num_orig_cols = scalar(@maf_col_headers);
                                            # insert ver_ref_allele column header before ver_tumor_allele_1 column
                                            push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'ver_tumor_allele_1'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_ref_allele'};
                                            # insert ver_vcf_filter column header before ver_status column
                                            push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'ver_status'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'ver_vcf_filter'};
                                            # insert tumor_ref_count column header before tumor_var_count column
                                            push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'tumor_var_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'tumor_ref_count'};
                                            # insert norm_ref_count column header before norm_var_count column
                                            push @splice_col_offsets, firstidx { $_ eq $maf_config{$maf_type}{'norm_var_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_config{$maf_type}{'norm_ref_count'};
                                            %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                            if ($debug{all} or $debug{maf_parse}) {
                                                print STDERR "\@maf_col_headers:\n", Dumper(\@maf_col_headers), "\n",
                                                             "\%maf_col_idx_by_name:\n", Dumper(\%maf_col_idx_by_name);
                                            }
                                            # get last row num
                                            my $last_row_num;
                                            for my $col_arrayref (@{$maf_sheet->{cell}}[1 .. $#{$maf_sheet->{cell}}]) {
                                                if (defined $last_row_num and $last_row_num != $#{$col_arrayref}) {
                                                    die "ERROR: MAF has unequal row count";
                                                }
                                                else {
                                                    $last_row_num = $#{$col_arrayref};
                                                }
                                            }
                                            # Spreadsheet::Read data rows start at 2 (after header row 1)
                                            for my $row_num (2 .. $last_row_num) {
                                                # Spreadsheet::Read stores empty cells as undef so change to ''
                                                my @maf_row_data = map { defined() ? $_ : '' } cellrow($maf_sheet, $row_num);
                                                # make sure data matrix is rectangular by adding blank missing fields if necessary
                                                if (scalar(@maf_row_data) < $maf_num_orig_cols) {
                                                    push @maf_row_data, ($maf_config{$maf_type}{'blank_val'}) x ( $maf_num_orig_cols - scalar(@maf_row_data) );
                                                }
                                                elsif (scalar(@maf_row_data) > $maf_num_orig_cols) {
                                                    die "ERROR: ", scalar(@maf_row_data), " data fields more than ",
                                                                   $maf_num_orig_cols, " column headers at line $.";
                                                }
                                                # insert new blank data fields
                                                for my $splice_col_offset (@splice_col_offsets) {
                                                    splice @maf_row_data, $splice_col_offset, 0, ($maf_config{$maf_type}{'blank_val'}) x 1;
                                                }
                                                my $disease_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'tumor_barcode'}}];
                                                my $normal_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_config{$maf_type}{'norm_barcode'}}];
                                                # if analyzing specific cases skip case if not in list
                                                if (defined $user_params{cases} and 
                                                   !exists $user_params{cases}{uc(get_barcode_info($disease_barcode)->{s_case_id})}) {
                                                    next;
                                                }
                                                if (!defined $ver_data_hashref or 
                                                    $disease_barcode ne $ver_data_hashref->{disease_barcode} or
                                                    $normal_barcode ne $ver_data_hashref->{normal_barcode}) {
                                                    # free up memory
                                                    $ver_data_hashref = undef;
                                                    $ver_data_hashref = get_verification_data(
                                                        $disease_barcode, $normal_barcode,
                                                        $tcs_data_dir, $rna_data_dir,
                                                    );
                                                }
                                                if (verify_maf_line($maf_type, \@maf_row_data, \%maf_col_idx_by_name, $ver_data_hashref)) {
                                                    push @{$maf_out_data_by_type{verified}}, \@maf_row_data;
                                                }
                                                else {
                                                    push @{$maf_out_data_by_type{unverified}}, \@maf_row_data;
                                                }
                                            }
                                        }
                                        else {
                                            die "ERROR: invalid file type";
                                        }
                                        if (!-d $dataset_output_dir) {
                                            make_path($dataset_output_dir, { chmod => 0700 }) 
                                                or die "ERROR: could not create $dataset_output_dir: $!\n";
                                        }
                                        my ($maf_basename, undef, $maf_ext) = fileparse($file_name, qr/\.\D*/);
                                        $maf_ext =~ s/\.xlsx?$/.txt/;
                                        my $sep_char = $file_name =~ /-/ ? '-' : '_';
                                        for my $type (qw(verified unverified)) {
                                            next if $type eq 'unverified' and $no_unverified;
                                            if (defined $maf_out_data_by_type{$type}) {
                                                my $maf_out_file_name = "${maf_basename}${sep_char}${type}${maf_ext}";
                                                if (!-f "$dataset_output_dir/$maf_out_file_name") {
                                                    push @{$maf_out_file_names_by_type{$type}}, $maf_out_file_name;
                                                    if ($verbose) {
                                                        print "Writing $maf_out_file_name\n";
                                                    }
                                                    open(my $maf_out_fh, '>', "$dataset_output_dir/$maf_out_file_name")
                                                        or die "ERROR: could not create $dataset_output_dir/$maf_out_file_name: $!";
                                                    print $maf_out_fh join("\t", @maf_col_headers), "\n";
                                                    for my $data_row_arrayref (@{$maf_out_data_by_type{$type}}) {
                                                        print $maf_out_fh join("\t", @{$data_row_arrayref}), "\n";
                                                    }
                                                    close($maf_out_fh);
                                                }
                                                else {
                                                    die "ERROR: $dataset_output_dir/$maf_out_file_name already exists";
                                                }
                                            }
                                            elsif ($verbose) {
                                                print "No $type data\n";
                                            }
                                        }
                                    }
                                },
                            }, "$dataset_dir/$data_level_dir_name");
                        }
                    }
                }
            }
        }
    }
}
exit;

sub get_verification_data {
    my ($disease_barcode, $normal_barcode,
        $tcs_data_dir, $rna_data_dir) = @_;
    my ($case_id, $disease_tissue_code, $disease_tissue_type) =
        @{get_barcode_info($disease_barcode)}{qw( case_id tissue_code tissue_type )};
    my ($normal_tissue_code, $normal_tissue_type) =
        @{get_barcode_info($normal_barcode)}{qw( tissue_code tissue_type )};
    print "-> $case_id $disease_tissue_code vs $normal_tissue_code\n" if $verbose;
    my $disease_tissue_code_regexp = $disease_tissue_type eq 'Primary'
                                   ? qr/(?:01|03|05|06|07|08|09)/
                                   : $disease_tissue_type eq 'Recurrent'
                                   ? qr/(?:02|04|40|41|42)/
                                   : $disease_tissue_type =~ /Normal/
                                   ? qr/(?:10|11|12|13|14|15|16|17|18)/
                                   : die "ERROR: disease barcode $disease_barcode not valid";
    my $normal_tissue_code_regexp = $normal_tissue_type =~ /Normal/
                                   ? qr/(?:10|11|12|13|14|15|16|17|18)/
                                   : die "ERROR: normal barcode $normal_barcode not valid";
    my (@tcs_data_dirs, @rna_data_dirs);
    push @tcs_data_dirs, $tcs_data_dir if -d $tcs_data_dir;
    push @rna_data_dirs, $rna_data_dir if -d $rna_data_dir;
    my $cache_file_suffix = !$conserve_memory ? '_i' : '';
    my $ver_data_hashref = {
        disease_barcode => $disease_barcode,
        normal_barcode => $normal_barcode,
    };
    for my $ver_data_file_type (@ver_data_file_types) {
        # do not load tcs snv maf data if tcs snv vcf data exists (saves memory)
        next if $ver_data_file_type =~ /^tcs_(tumor|normal)_snv_maf$/ and 
                defined $ver_data_hashref->{"tcs_$1_snv_vcf"};
        my $cache_file_prefix = $ver_data_file_type =~ /strelka/ 
                              ? "${disease_barcode}_${normal_barcode}" 
                              : $ver_data_file_type =~ /tumor/
                              ? $disease_barcode
                              : $ver_data_file_type =~ /normal/
                              ? $normal_barcode
                              : die "ERROR invalid data type $ver_data_file_type";
        my @search_dirs = $ver_data_file_type =~ /^tcs/
                        ? @tcs_data_dirs
                        : $ver_data_file_type =~ /^rna/
                        ? @rna_data_dirs
                        : die "ERROR invalid data type $ver_data_file_type";
        my $cache_file_name = "${cache_file_prefix}_${ver_data_file_type}${cache_file_suffix}.pls";
        if (!-f "$cache_dir/$cache_file_name" or $rebuild_cache) {
            my $tissue_code_regexp = $ver_data_file_type =~ /strelka/
                                   ? qr/(?:$disease_tissue_code|$normal_tissue_code)/
                                   : $ver_data_file_type =~ /tumor/
                                   ? qr/$disease_tissue_code/
                                   : $ver_data_file_type =~ /normal/
                                   ? qr/$normal_tissue_code/
                                   : die "ERROR: invalid data type $ver_data_file_type";
            my $tissue_code_expanded_regexp = $ver_data_file_type =~ /strelka/
                                            ? qr/(?:$disease_tissue_code_regexp|$normal_tissue_code_regexp)/
                                            : $ver_data_file_type =~ /tumor/
                                            ? qr/$disease_tissue_code_regexp/
                                            : $ver_data_file_type =~ /normal/
                                            ? qr/$normal_tissue_code_regexp/
                                            : die "ERROR: invalid data type $ver_data_file_type";
            my $ver_data_file_suffix_regexp = $ver_data_file_type =~ /^tcs_strelka_(snv|indel)_vcf$/
                                            ? qr/.+?\.somatic\.$1\.vcf(\.txt)?/
                                            : $ver_data_file_type =~ /^tcs_(tumor|normal)_(snv|indel)_vcf$/
                                            ? qr/.+?\.vcf(\.txt)?/
                                            : $ver_data_file_type =~ /maf$/
                                            ? qr/.+?\.maf(\.txt)?/
                                            : $ver_data_file_type =~ /rna_(tumor|normal)_indel_vcf$/
                                            ? qr/\.indel\.vcf(\.txt)?/
                                            : die "ERROR invalid data type $ver_data_file_type";
            my $ver_data_file_regexp = 
                $ver_data_file_type =~ /strelka/
                    ? qr/
                          $case_id-
                          $tissue_code_regexp
                          $OCG_BARCODE_END_REGEXP
                          _
                          $case_id-
                          $tissue_code_regexp
                          $OCG_BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix
                    : qr/
                          $case_id-
                          $tissue_code_regexp
                          $OCG_BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix;
            my $ver_data_file_expanded_regexp = 
                $ver_data_file_type =~ /strelka/
                    ? qr/
                          $case_id-
                          $tissue_code_expanded_regexp
                          $OCG_BARCODE_END_REGEXP
                          _
                          $case_id-
                          $tissue_code_expanded_regexp
                          $OCG_BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix
                    : qr/
                          $case_id-
                          $tissue_code_expanded_regexp
                          $OCG_BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix;
            my @ver_data_files = Path::Iterator::Rule->new->file->name(
                $ver_data_file_regexp
            )->all_fast(@search_dirs);
            if (!@ver_data_files) {
                @ver_data_files = Path::Iterator::Rule->new->file->name(
                    $ver_data_file_expanded_regexp
                )->all_fast(@search_dirs);
            }
            if (@ver_data_files) {
                # init
                $ver_data_hashref->{$ver_data_file_type} = {};
                for my $ver_data_file (@ver_data_files) {
                    add_mutation_file_data($ver_data_hashref, $ver_data_file_type, $ver_data_file);
                    if ($debug{all} or $debug{ver_data}) {
                        my $ver_data_file_name = fileparse($ver_data_file);
                        print STDERR "$ver_data_file_name\n" if -f STDERR;
                    }
                }
                if (!$no_cache) {
                    print "Caching $cache_file_name\n";
                    lock_nstore($ver_data_hashref->{$ver_data_file_type}, "$cache_dir/$cache_file_name")
                        or die "ERROR: could not serialize $cache_dir/$cache_file_name: $!";
                }
                if ($debug{all} or $debug{ver_data}) {
                    print STDERR Dumper($ver_data_hashref->{$ver_data_file_type});
                }
            }
            elsif ($verbose) {
                (my $ver_data_file_type_phrase = $ver_data_file_type) =~ s/_/ /g;
                $ver_data_file_type_phrase =~ s/(tcs|rna|maf|vcf)/\U$1/g;
                print "No $ver_data_file_type_phrase\n";
            }
        }
        else {
            print "Loading $cache_file_name\n";
            $ver_data_hashref->{$ver_data_file_type} = lock_retrieve("$cache_dir/$cache_file_name")
                or die "ERROR: could not deserialize $cache_dir/$cache_file_name: $!";
        }
    }
    return $ver_data_hashref;
}

sub verify_maf_line {
    my ($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $ver_data_hashref) = @_;
    my $save_line;
    # already verified somatic mutations
    if (
        (
         $maf_type eq 'CGI' and
         defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_status'}}] and
         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_status'}}]) eq lc($maf_config{$maf_type}{'ver_status_val'})
        )
        or
        (
         defined $maf_config{$maf_type}{'val_status'} and
         defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'val_status'}}] and
         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'val_status'}}]) eq lc($maf_config{$maf_type}{'val_status_val'}) and
         defined $maf_config{$maf_type}{'mut_status'} and
         defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'mut_status'}}] and
         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'mut_status'}}]) eq lc($maf_config{$maf_type}{'mut_status_val'})
        )
    ) {
        $save_line++;
        if (
            defined $maf_config{$maf_type}{'tumor_var_ratio'} and 
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}] eq $maf_config{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}] ne $maf_config{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}] ne $maf_config{$maf_type}{'blank_val'}
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}] =
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}] > 0
                    ? sprintf(
                        $count_ratio_format, 
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}] /
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}]
                      )
                    : 0;
        }
        if (
            defined $maf_config{$maf_type}{'norm_var_ratio'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}] eq $maf_config{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_var_count'}}] ne $maf_config{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}] ne $maf_config{$maf_type}{'blank_val'}
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}] =
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}] > 0
                    ? sprintf(
                        $count_ratio_format, 
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_var_count'}}] /
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}]
                      )
                    : 0;
        }
    }
    my $chr = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'chr'}}];
    my $pos = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'pos'}}];
    # snv
    if (uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'variant_type'}}]) eq 'SNP') {
        #if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ref_allele'}}] or
        #             $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ref_allele'}}] eq $maf_config{$maf_type}{'blank_val'}) {
        #    die 'ERROR: Reference_Allele field is empty';
        #}
        #elsif ($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ref_allele'}}] !~ /^(A|C|G|T)$/) {
        #    die "ERROR: Reference_Allele bad value '$maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ref_allele'}}]'";
        #}
        #for my $tumor_seq ($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_1'}}],
        #                   $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{'$maf_config{$maf_type}{'tumor_allele_2'}}]) {
        #    if (defined $tumor_seq and $tumor_seq ne $maf_config{$maf_type}{'blank_val'} and $tumor_seq ne '?') {
        #        
        #    }
        #}
        #my $maf_snv;
        #if (defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_1'}}] and
        #    $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_1'}}] ne $maf_config{$maf_type}{'blank_val'} and
        #    $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ref_allele'}}] ne '?'
        #    $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_1'}}]) {
        #    $maf_snv = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_1'}}];
        #}
        #elsif (defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_2'}}] and
        #       $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_2'}}] ne $maf_config{$maf_type}{'blank_val'} and
        #       $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ref_allele'}}] ne 
        #       $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_2'}}]) {
        #    $maf_snv = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'tumor_allele_2'}}];
        #}
        #else {
        #    die 'ERROR: could not determine SNV';
        #}
        # tcs strelka snv vcf
        if (
            my @tcs_strelka_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_strelka_snv_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_strelka_snv_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_strelka_snv_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_strelka_snv_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_strelka_snv_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "TCS";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCS";
            }
            my $data_to_insert_hashref;
            my $tcs_strelka_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_strelka_snv_vcf}->{col_idx_by_name};
            for my $tcs_strelka_snv_arrayref (@tcs_strelka_snvs) {
                my @format_fields = split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'FORMAT'}]);
                my $tot_format_idx = firstidx { $_ eq 'DP' } @format_fields;
                die "ERROR: could not find format index for DP" if $tot_format_idx < 0;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, 
                    (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$tot_format_idx];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, 
                    (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$tot_format_idx];
                my $ref_allele = $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                if ($ref_allele =~ /,/) {
                    my ($tumor_ref_count, $normal_ref_count);
                    for my $ref_allele (split(',', $ref_allele)) {
                        my $ref_format_idx = firstidx { $_ eq "${ref_allele}U" } @format_fields;
                        die "ERROR: could not find format index for ${ref_allele}U" if $ref_format_idx < 0;
                        $tumor_ref_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$ref_format_idx]))[0];
                        $normal_ref_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$ref_format_idx]))[0];
                    }
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, $normal_ref_count;
                }
                else {
                    my $ref_format_idx = firstidx { $_ eq "${ref_allele}U" } @format_fields;
                    die "ERROR: could not find format index for ${ref_allele}U" if $ref_format_idx < 0;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$ref_format_idx]))[0];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$ref_format_idx]))[0];
                }
                my $alt_allele = $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    if ($alt_allele =~ /,/) {
                        my ($tumor_alt_count, $normal_alt_count);
                        for my $alt_allele (split(',', $alt_allele)) {
                            my $alt_format_idx = firstidx { $_ eq "${alt_allele}U" } @format_fields;
                            die "ERROR: could not find format index for ${alt_allele}U" if $alt_format_idx < 0;
                            $tumor_alt_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$alt_format_idx]))[0];
                            $normal_alt_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$alt_format_idx]))[0];
                        }
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, $normal_alt_count;
                    }
                    else {
                        my $alt_format_idx = firstidx { $_ eq "${alt_allele}U" } @format_fields;
                        die "ERROR: could not find format index for ${alt_allele}U" if $alt_format_idx < 0;
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, 
                            (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$alt_format_idx]))[0];
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, 
                            (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$alt_format_idx]))[0];
                    }
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                }
                else {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, 0;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, 0;
                }
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format, 
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
                if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                              )
                            : 0;
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # tcs tumor snv vcf
        if (
            my @tcs_tumor_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_tumor_snv_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_tumor_snv_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_tumor_snv_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_tumor_snv_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_tumor_snv_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "TCM";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCM";
            }
            my $data_to_insert_hashref;
            my $tcs_tumor_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_tumor_snv_vcf}->{col_idx_by_name};
            for my $tcs_tumor_snv_arrayref (@tcs_tumor_snvs) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'INFO'}]);
                my @dp4_values = split(',', $info_fields{'DP4'});
                die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                my $tumor_ref_count = sum(@dp4_values[0..1]);
                my $tumor_alt_count = sum(@dp4_values[2..3]);
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                my $ref_allele = $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $alt_allele = $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    my @format_fields = split(':', $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'FORMAT'}]);
                    my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                    die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                    # column name with genotype data is verification barcode (not fixed and not source barcode) 
                    # so can be messy so since we know it's last column just use array index
                    my $genotype = (split(':', $tcs_tumor_snv_arrayref->[$#{$tcs_tumor_snv_arrayref}]))[0];
                    if ($genotype eq '1/1') {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_1'}}}, $alt_allele;
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    elsif ($genotype eq '0/1') {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_1'}}}, $ref_allele;
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    else {
                        die "ERROR: genotype '$genotype' not supported";
                    }
                }
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # tcs normal snv vcf
            if (
                my @tcs_normal_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_normal_snv_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_normal_snv_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_normal_snv_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_normal_snv_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_normal_snv_vcf}->{data}}
            ) {
                my $tcs_normal_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_normal_snv_vcf}->{col_idx_by_name};
                for my $tcs_normal_snv_arrayref (@tcs_normal_snvs) {
                    my %info_fields = map {
                        m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                    } split(';', $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'INFO'}]);
                    my @dp4_values = split(',', $info_fields{'DP4'});
                    die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                    my $norm_ref_count = sum(@dp4_values[0..1]);
                    my $norm_alt_count = sum(@dp4_values[2..3]);
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, $norm_ref_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, $norm_alt_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, $norm_ref_count + $norm_alt_count;
                    my $ref_allele = $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'REF'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                    my $alt_allele = $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'ALT'}];
                    if ($alt_allele ne '.') {
                        my @format_fields = split(':', $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'FORMAT'}]);
                        my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                        die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                        # column name with genotype data is verification barcode (not fixed and not source barcode) 
                        # so can be messy so since we know it's last column just use array index
                        my $genotype = (split(':', $tcs_normal_snv_arrayref->[$#{$tcs_normal_snv_arrayref}]))[0];
                        if ($genotype eq '1/1') {
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_1'}}}, $alt_allele;
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        elsif ($genotype eq '0/1') {
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_1'}}}, $ref_allele;
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        else {
                            die "ERROR: genotype '$genotype' not supported";
                        }
                    }
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'FILTER'}];
                    if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # tcs tumor snv maf
        elsif (
            @tcs_tumor_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_tumor_snv_maf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_tumor_snv_maf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_tumor_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_tumor_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                  } @{$ver_data_hashref->{tcs_tumor_snv_maf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "TCM";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCM";
            }
            my $data_to_insert_hashref;
            my $tcs_tumor_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_tumor_snv_maf}->{col_idx_by_name};
            for my $tcs_tumor_snv_arrayref (@tcs_tumor_snvs) {
                my $tumor_ref_count = $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                my $tumor_alt_count =
                    $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}] != 
                    $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        ? $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        : $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Reference_Allele'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_1'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # tcs normal snv maf
            if (
                my @tcs_normal_snvs = !$conserve_memory
                    ? exists $ver_data_hashref->{tcs_normal_snv_maf}->{data}->{"$chr:$pos"}
                        ? @{$ver_data_hashref->{tcs_normal_snv_maf}->{data}->{"$chr:$pos"}}
                        : ()
                    : grep {
                          $chr eq $_->[$ver_data_hashref->{tcs_normal_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                          $pos eq $_->[$ver_data_hashref->{tcs_normal_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                      } @{$ver_data_hashref->{tcs_normal_snv_maf}->{data}}
            ) {
                my $tcs_normal_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_normal_snv_maf}->{col_idx_by_name};
                for my $tcs_normal_snv_arrayref (@tcs_normal_snvs) {
                    my $normal_ref_count = $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, $normal_ref_count;
                    my $normal_alt_count =
                        $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}] != 
                        $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            ? $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            : $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele2_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, $normal_ref_count + $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_1'}}}, $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele1'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele2'}];
                    if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # rna tumor snv maf
        if (
            my @rna_tumor_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{rna_tumor_snv_maf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{rna_tumor_snv_maf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{rna_tumor_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                      $pos eq $_->[$ver_data_hashref->{rna_tumor_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                  } @{$ver_data_hashref->{rna_tumor_snv_maf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "RNA";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}RNA";
            }
            my $data_to_insert_hashref;
            my $rna_tumor_snv_col_idx_by_name_hashref = $ver_data_hashref->{rna_tumor_snv_maf}->{col_idx_by_name};
            for my $rna_tumor_snv_arrayref (@rna_tumor_snvs) {
                my $tumor_ref_count = $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                my $tumor_alt_count =
                    $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}] != 
                    $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        ? $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        : $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Reference_Allele'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_1'}}}, $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # rna normal snv maf
            if (
                my @rna_normal_snvs = !$conserve_memory
                    ? exists $ver_data_hashref->{rna_normal_snv_maf}->{data}->{"$chr:$pos"}
                        ? @{$ver_data_hashref->{rna_normal_snv_maf}->{data}->{"$chr:$pos"}}
                        : ()
                    : grep {
                          $chr eq $_->[$ver_data_hashref->{rna_normal_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                          $pos eq $_->[$ver_data_hashref->{rna_normal_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                      } @{$ver_data_hashref->{rna_normal_snv_maf}->{data}}
            ) {
                my $rna_normal_snv_col_idx_by_name_hashref = $ver_data_hashref->{rna_normal_snv_maf}->{col_idx_by_name};
                for my $rna_normal_snv_arrayref (@rna_normal_snvs) {
                    my $normal_ref_count = $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, $normal_ref_count;
                    my $normal_alt_count =
                        $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}] != 
                        $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            ? $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            : $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele2_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, $normal_ref_count + $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_1'}}}, $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele1'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele2'}];
                    if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
    }
    # indel
    elsif (uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'variant_type'}}]) eq 'INS' or
           uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'variant_type'}}]) eq 'DEL' or
           uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'variant_type'}}]) eq 'SUB') {
        # tcs strelka indel vcf
        if (
            my @tcs_strelka_indels = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_strelka_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_strelka_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_strelka_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_strelka_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_strelka_indel_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "TCS";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCS";
            }
            my $data_to_insert_hashref;
            my $tcs_strelka_indel_col_idx_by_name_hashref = $ver_data_hashref->{tcs_strelka_indel_vcf}->{col_idx_by_name};
            for my $tcs_strelka_indel_arrayref (@tcs_strelka_indels) {
                my @format_fields = split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'FORMAT'}]);
                my $tot_format_idx = firstidx { $_ eq 'DP' } @format_fields;
                die "ERROR: could not find format index for DP" if $tot_format_idx < 0;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, 
                    (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'TUMOR'}]))[$tot_format_idx];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, 
                    (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'NORMAL'}]))[$tot_format_idx];
                my $ref_allele = $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $ref_format_idx = firstidx { $_ eq 'TAR' } @format_fields;
                die "ERROR: could not find format index for TAR" if $ref_format_idx < 0;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, 
                    (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'TUMOR'}]))[$ref_format_idx]))[0];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, 
                    (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'NORMAL'}]))[$ref_format_idx]))[0];
                my $alt_allele = $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    my $alt_format_idx = firstidx { $_ eq 'TIR' } @format_fields;
                    die "ERROR: could not find format index for TAR" if $alt_format_idx < 0;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'TUMOR'}]))[$alt_format_idx]))[0];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'NORMAL'}]))[$alt_format_idx]))[0];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                }
                else {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, 0;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, 0;
                }
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
                if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                              )
                            : 0;
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # tcs tumor indel vcf
        if (
            my @tcs_tumor_indels = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_tumor_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_tumor_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_tumor_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_tumor_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_tumor_indel_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "TCM";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCM";
            }
            my $data_to_insert_hashref;
            my $tcs_tumor_indel_col_idx_by_name_hashref = $ver_data_hashref->{tcs_tumor_indel_vcf}->{col_idx_by_name};
            for my $tcs_tumor_indel_arrayref (@tcs_tumor_indels) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'INFO'}]);
                my @dp4_values = split(',', $info_fields{'DP4'});
                die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                my $tumor_ref_count = sum(@dp4_values[0..1]);
                my $tumor_alt_count = sum(@dp4_values[2..3]);
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                my $ref_allele = $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $alt_allele = $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    my @format_fields = split(':', $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'FORMAT'}]);
                    my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                    die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                    # column name with genotype data is verification barcode (not fixed and not source barcode) 
                    # so can be messy so since we know it's last column just use array index
                    my $genotype = (split(':', $tcs_tumor_indel_arrayref->[$#{$tcs_tumor_indel_arrayref}]))[0];
                    if ($genotype eq '1/1') {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_1'}}}, $alt_allele;
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    elsif ($genotype eq '0/1') {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_1'}}}, $ref_allele;
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    else {
                        die "ERROR: genotype '$genotype' not supported";
                    }
                }
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # tcs normal indel vcf
            if (
                my @tcs_normal_indels = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_normal_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_normal_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_normal_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_normal_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_normal_indel_vcf}->{data}}
            ) {
                my $tcs_normal_indel_col_idx_by_name_hashref = $ver_data_hashref->{tcs_normal_indel_vcf}->{col_idx_by_name};
                for my $tcs_normal_indel_arrayref (@tcs_normal_indels) {
                    my %info_fields = map {
                        m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                    } split(';', $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'INFO'}]);
                    my @dp4_values = split(',', $info_fields{'DP4'});
                    die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                    my $norm_ref_count = sum(@dp4_values[0..1]);
                    my $norm_alt_count = sum(@dp4_values[2..3]);
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_ref_count'}}}, $norm_ref_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, $norm_alt_count;
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, $norm_ref_count + $norm_alt_count;
                    my $ref_allele = $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'REF'}];
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                    my $alt_allele = $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'ALT'}];
                    if ($alt_allele ne '.') {
                        my @format_fields = split(':', $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'FORMAT'}]);
                        my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                        die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                        # vcf column name is the verification barcode (not source barcode) can be messy so since we know it's last column just use array index
                        my $genotype = (split(':', $tcs_normal_indel_arrayref->[$#{$tcs_normal_indel_arrayref}]))[0];
                        if ($genotype eq '1/1') {
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_1'}}}, $alt_allele;
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        elsif ($genotype eq '0/1') {
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_1'}}}, $ref_allele;
                            push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        else {
                            die "ERROR: genotype '$genotype' not supported";
                        }
                    }
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'FILTER'}];
                    if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # rna tumor indel vcf
        if (
            my @rna_tumor_indels = !$conserve_memory
                ? exists $ver_data_hashref->{rna_tumor_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{rna_tumor_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{rna_tumor_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{rna_tumor_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{rna_tumor_indel_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] = "RNA";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_method'}}] .= "${maf_sep_char}RNA";
            }
            my $data_to_insert_hashref;
            my $rna_tumor_indel_col_idx_by_name_hashref = $ver_data_hashref->{rna_tumor_indel_vcf}->{col_idx_by_name};
            for my $rna_tumor_indel_arrayref (@rna_tumor_indels) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'INFO'}]);
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}, $info_fields{'MAX_SUPPORT'};
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}, $info_fields{'MAX_SUPPORT'};
                my $ref_allele = $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $alt_allele = $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                }
                push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_config{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # rna normal indel vcf
            if (
                my @rna_normal_indels = !$conserve_memory
                    ? exists $ver_data_hashref->{rna_normal_indel_vcf}->{data}->{"$chr:$pos"}
                        ? @{$ver_data_hashref->{rna_normal_indel_vcf}->{data}->{"$chr:$pos"}}
                        : ()
                    : grep {
                          $chr eq $_->[$ver_data_hashref->{rna_normal_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                          $pos eq $_->[$ver_data_hashref->{rna_normal_indel_vcf}->{col_idx_by_name}->{'POS'}]
                      } @{$ver_data_hashref->{rna_normal_indel_vcf}->{data}}
            ) {
                my $rna_normal_indel_col_idx_by_name_hashref = $ver_data_hashref->{rna_normal_indel_vcf}->{col_idx_by_name};
                for my $rna_normal_indel_arrayref (@rna_normal_indels) {
                    my %info_fields = map {
                        m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                    } split(';', $rna_normal_indel_arrayref->[$rna_normal_indel_col_idx_by_name_hashref->{'INFO'}]);
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}, $info_fields{'MAX_SUPPORT'};
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}, $info_fields{'MAX_SUPPORT'};
                    my $alt_allele = $rna_normal_indel_arrayref->[$rna_normal_indel_col_idx_by_name_hashref->{'ALT'}];
                    if ($alt_allele ne '.') {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                    }
                    push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'ver_vcf_filter'}}}, $rna_normal_indel_arrayref->[$rna_normal_indel_col_idx_by_name_hashref->{'FILTER'}];
                    if (defined $maf_config{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_config{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
    }
    else {
        die "ERROR: unsupported variant type '$maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'variant_type'}}]'";
    }
    if ($save_line) {
        if (
            !defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_status'}}] or
                     $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_status'}}] eq $maf_config{$maf_type}{'blank_val'} or
                     $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_status'}}] =~ /un(known|tested)/i
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'ver_status'}}] = 
                $maf_config{$maf_type}{'ver_status_val'};
        }
        if (
            defined $maf_config{$maf_type}{'val_status'} and (
                !defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'val_status'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'val_status'}}] eq $maf_config{$maf_type}{'blank_val'} or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'val_status'}}] =~ /un(known|tested)/i
                )
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_config{$maf_type}{'val_status'}}] = 
                $maf_config{$maf_type}{'val_status_val'};
        }
        if ($debug{ver_step}) {
            local $Data::Dumper::Indent = 0;
            print Dumper($maf_row_data_arrayref), "\n";
            <STDIN>;
        }
    }
    return $save_line;
}

sub add_mutation_file_data {
    my ($ver_data_hashref, $ver_data_file_type, $data_file) = @_;
    my $file_name = fileparse($data_file);
    my ($file_type) = $file_name =~ /\.(vcf|maf)(?:\.txt)?$/i;
    die "ERROR: invalid file type $file_name" unless $file_type;
    $file_type = lc($file_type);
    my $chr_col_name = $file_type eq 'maf' ? 'Chromosome'     : 'CHROM';
    my $pos_col_name = $file_type eq 'maf' ? 'Start_Position' : 'POS';
    my %col_idx_by_name;
    print "Loading $file_name\n" if $verbose;
    open(my $fh, '<', $data_file) or die "ERROR: could not open $data_file";
    while (<$fh>) {
        s/\s+$//;
        if (!%col_idx_by_name and (
            ($file_type eq 'maf' and !m/^#/) or
            ($file_type eq 'vcf' and m/^#(?!#)/) 
        )) {
            if ($file_type eq 'vcf') {
                s/^#//;
                if (!m/^CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO/) {
                    die "ERROR: invalid VCF column header:\n$_";
                }
            }
            my @col_headers = split /\t/;
            for (@col_headers) {
                s/^\s+//;
                s/\s+$//;
            }
            %col_idx_by_name = map { $col_headers[$_] => $_ } 0 .. $#col_headers;
            if (!defined $ver_data_hashref->{$ver_data_file_type} or
                !defined $ver_data_hashref->{$ver_data_file_type}->{col_idx_by_name}) {
                $ver_data_hashref->{$ver_data_file_type}->{col_idx_by_name} = \%col_idx_by_name;
            }
        }
        elsif (%col_idx_by_name) {
            my @row_data = split /\t/;
            for (@row_data) {
                s/^\s+//;
                s/\s+$//;
            }
            # for tcs mpileup vcfs with snv and indel data
            # in same file split up storage of variants
            if ($ver_data_file_type =~ /^tcs_(tumor|normal)_(snv|indel)_vcf$/) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $row_data[$ver_data_hashref->{$ver_data_file_type}->{col_idx_by_name}->{'INFO'}]);
                next if (!exists $info_fields{'INDEL'} and $ver_data_file_type =~ /^tcs_(tumor|normal)_indel_vcf$/) or
                        ( exists $info_fields{'INDEL'} and $ver_data_file_type =~ /^tcs_(tumor|normal)_snv_vcf$/);
            }
            if (!$conserve_memory) {
                push @{$ver_data_hashref->{$ver_data_file_type}->{data}->{
                    "$row_data[$col_idx_by_name{$chr_col_name}]:$row_data[$col_idx_by_name{$pos_col_name}]"
                }}, \@row_data;
            }
            else {
                push @{$ver_data_hashref->{$ver_data_file_type}->{data}}, \@row_data;
            }
        }
        elsif (
            $file_type eq 'maf' or
            ($file_type eq 'vcf' and !m/^##/)
        ) {
            die "ERROR: invalid \U$file_type\E line $.";
        }
    }
    close($fh);
}

sub insert_maf_data {
    my ($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref) = @_;
    for my $col_name (keys %{$data_to_insert_hashref}) {
        my $field_str = 
            $col_name eq $maf_config{$maf_type}{'ver_ref_allele'}
                ? (
                  scalar(@{$data_to_insert_hashref->{$col_name}}) > 1 and
                  scalar(keys(%{{ map { $_ => 1 } @{$data_to_insert_hashref->{$col_name}} }})) > 1
                )
                    ? join('/', @{$data_to_insert_hashref->{$col_name}})
                    : $data_to_insert_hashref->{$col_name}->[0]
                : scalar(@{$data_to_insert_hashref->{$col_name}}) > 1
                    ? join('/', @{$data_to_insert_hashref->{$col_name}})
                    : $data_to_insert_hashref->{$col_name}->[0];
        if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] or
                     $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] eq $maf_config{$maf_type}{'blank_val'}) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] = $field_str;
        }
        else {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] .= "${maf_sep_char}${field_str}";
        }
    }
}

__END__

=head1 NAME 

generate_verified_somatic_mafs.pl - Generate Verified Somatic MAFs

=head1 SYNOPSIS

 generate_verified_somatic_mafs.pl [options] <program name(s)> <project name(s)> <data type(s)> <case(s)>
 
 Parameters:
    <program name(s)>           Comma-separated list of program name(s): TARGET, CGCI (optional, default: all programs)
    <project name(s)>           Comma-separated list of disease project name(s) (optional, default: all program projects)
    <data type(s)>              Comma-separated list of data type(s) (optional, default: all project data types)
    <data set(s)>               Comma-separated list of data set(s) (optional, default: all project data type datasets)
    <case(s)>                   Comma-separated list of case IDs to analyze (optional, default: all cases)
 
 Options:
    --output-dir=<path>         Alternate output directory (default: $PWD)
    --cache-dir=<path>          Alternate cache directory location (default: config var $CACHE_DIR/verified_mafs)
    --rebuild-cache             Rebuild verification data cache
    --no-cache                  Do not cache verification data
    --conserve-memory           Use less memory
    --use-cgi-filtered-mafs     Use CGI somatic filtered MAFs (only applicable when verifying a CGI WGS dataset)
    --verbose                   Be verbose
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
