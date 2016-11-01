#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd qw(realpath);
use File::Basename qw(fileparse);
use File::Copy qw(copy);
use File::Find;
use File::Path 2.11 qw(make_path remove_tree);
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(max);
use List::MoreUtils qw(any none);
use Pod::Usage qw(pod2usage);
use POSIX qw(strftime);
use Sort::Key::Natural qw(natsort mkkey_natural);
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $CGI_CASE_DIR_REGEXP = qr/${CASE_REGEXP}(?:(?:-|_)\d+)?/;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;

# sort by file path (file column idx 1)
sub manifest_by_file_path {
    my $a_file_path = (split(' ', $a, 2))[1];
    my $b_file_path = (split(' ', $b, 2))[1];
    my @a_path_parts = File::Spec->splitdir($a_file_path);
    my @b_path_parts = File::Spec->splitdir($b_file_path);
    # sort top-level files last
    if ($#a_path_parts != 0 and 
        $#b_path_parts == 0) {
        return -1;
    }
    elsif ($#a_path_parts == 0 and 
           $#b_path_parts != 0) {
        return 1;
    }
    for my $i (0 .. max($#a_path_parts, $#b_path_parts)) {
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

# config
my @project_names = qw(
    ALL
    AML
    CCSK
    NBL
    MDLS-NBL
    OS
    OS-Toronto
    WT
);
my @job_types = qw(
    BCCA
    FullMafsVcfs
    Germline
    SomaticVcfs
    TEMP
);
my $target_data_dir = '/local/target/data';
my $target_download_ctrld_dir = '/local/target/download/Controlled';
my $data_type_dir_name = 'WGS';
my $cgi_dir_name = 'CGI';
my $default_manifest_file_name = 'MANIFEST.txt';
my @target_cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);
my @target_cgi_manifest_file_names = qw(
    manifest.all.unencrypted
    manifest.dcc.unencrypted
);
my @target_cgi_skip_file_names = qw(
    manifest.all.unencrypted.sig
    sha256output
    idMap.tsv
);
my @param_groups = qw(
    job_types
    projects
);
my $owner_name = 'ocg-dcc-adm';
my $group_name = 'target-dn-adm';
my $ctrld_group_name = 'target-dn-ctrld';
my $dir_mode = 0550;
my $file_mode = 0440;

my $verbose = 0;
my $dry_run = 0;
my $clean_only = 0;
my $debug = 0;
GetOptions(
    'verbose' => \$verbose,
    'dry-run' => \$dry_run,
    'clean-only' => \$clean_only,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if ($< != 0 and !$dry_run) {
    pod2usage(
        -message => 'Script must be run with sudo',
        -verbose => 0,
    );
}
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/;
        my (@valid_user_params, @invalid_user_params, @valid_choices);
        my @user_params = split(',', $ARGV[$i]);
        if ($param_groups[$i] eq 'job_types') {
            for my $job_type (@job_types) {
                push @valid_user_params, $job_type if any { m/^$job_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @job_types;
            }
            @valid_choices = @job_types;
        }
        elsif ($param_groups[$i] eq 'projects') {
            for my $project_name (@project_names) {
                push @valid_user_params, $project_name if any { m/^$project_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @project_names;
            }
            @valid_choices = @project_names;
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
print STDERR "\%user_params:\n", Dumper(\%user_params) if $debug;
my $owner_uid = getpwnam($owner_name)
    or die "ERROR: couldn't get uid for $owner_name: $!\n";
my $ctrld_group_gid = getgrnam($ctrld_group_name)
    or die "ERROR: couldn't get gid for $ctrld_group_name\n";
for my $job_type (@job_types) {
    next if defined $user_params{job_types} and none { $job_type eq $_ } @{$user_params{job_types}};
    for my $project_name (@project_names) {
        next if defined $user_params{projects} and none { $project_name eq $_ } @{$user_params{projects}};
        print "[$job_type $project_name]\n";
        my ($disease_proj, $subproject) = split /-(?=NBL|PPTP|Toronto|Brazil)/, $project_name, 2;
        my $project_dir = $disease_proj;
        if (defined $subproject) {
            if ($disease_proj eq 'MDLS') {
                if ($subproject eq 'NBL') {
                    $project_dir = "$project_dir/NBL";
                }
                elsif ($subproject eq 'PPTP') {
                    $project_dir = "$project_dir/PPTP";
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid subproject '$subproject'\n";
                }
            }
            elsif ($disease_proj eq 'OS') {
                if ($subproject eq 'Toronto') {
                    $project_dir = "$project_dir/Toronto";
                }
                elsif ($subproject eq 'Brazil') {
                    $project_dir = "$project_dir/Brazil";
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid subproject '$subproject'\n";
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid disease project '$disease_proj'\n";
            }
        }
        my $data_type_dir = "$target_download_ctrld_dir/$project_dir/$data_type_dir_name";
        my $dataset_dir_name = $project_name eq 'ALL' 
                             ? 'Phase1+2'
                             : '';
        my $dataset_dir = $dataset_dir_name
                        ? "$data_type_dir/$dataset_dir_name"
                        : $data_type_dir;
        my $dataset_cgi_dir = "$dataset_dir/$cgi_dir_name";
        my $output_dataset_cgi_dir;
        if (any { $job_type eq $_ } qw( BCCA Germline TEMP )) {
            $output_dataset_cgi_dir = $dataset_dir_name
                                    ? "$target_data_dir/$job_type/$project_dir/$data_type_dir_name/$dataset_dir_name/current/$cgi_dir_name"
                                    : "$target_data_dir/$job_type/$project_dir/$data_type_dir_name/current/$cgi_dir_name";
        }
        my (@cgi_data_dirs, @output_cgi_data_dirs);
        for my $data_dir_name (@target_cgi_data_dir_names) {
            my $cgi_data_dir = "$dataset_cgi_dir/$data_dir_name";
            push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
            my $output_cgi_data_dir = $job_type eq 'FullMafsVcfs'
                                    ? $dataset_dir_name
                                        ? "$target_download_ctrld_dir/$project_dir/$data_type_dir_name/$dataset_dir_name/L3/mutation/$cgi_dir_name/$job_type"
                                        : "$target_download_ctrld_dir/$project_dir/$data_type_dir_name/L3/mutation/$cgi_dir_name/$job_type"
                                    : $job_type eq 'SomaticVcfs'
                                    ? $dataset_dir_name
                                        ? "$target_data_dir/$project_dir/$data_type_dir_name/$dataset_dir_name/current/L3/mutation/$cgi_dir_name/$job_type"
                                        : "$target_data_dir/$project_dir/$data_type_dir_name/current/L3/mutation/$cgi_dir_name/$job_type"
                                    : "$output_dataset_cgi_dir/$data_dir_name";
            if (none { $_ eq $output_cgi_data_dir } @output_cgi_data_dirs) {
                push @output_cgi_data_dirs, $output_cgi_data_dir;
            }
        }
        if ($debug) {
            print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs),
                         "\@output_cgi_data_dirs:\n", Dumper(\@output_cgi_data_dirs);
        }
        # clean existing datasets
        if (grep { -d } @output_cgi_data_dirs) {
            print "Removing existing datasets:\n",
                  join("\n", @output_cgi_data_dirs), "\n";
            find({
                bydepth => 1,
                preprocess => sub {
                    natsort @_;
                },
                wanted => sub {
                    if (-d) {
                        my $dir_name = $_;
                        my $dir = $File::Find::name;
                        if (( none { $dir eq $_ } @output_cgi_data_dirs ) and -z $dir) {
                            print "Deleting $dir\n" if $verbose;
                            if (!$dry_run) {
                                remove_tree($dir, { error => \my $err });
                                if (@{$err}) {
                                    for my $diag (@{$err}) {
                                        my ($err_file, $message) = %{$diag};
                                        if ($err_file eq '') {
                                            die "ERROR: could not delete $dir: $message";
                                        }
                                        else {
                                            die "ERROR: could not delete $err_file: $message";
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        my $file_name = $_;
                        my $file = $File::Find::name;
                        return if ( any { $job_type eq $_ } qw( FullMafsVcfs SomaticVcfs ) ) and 
                                  $file_name eq $default_manifest_file_name;
                        print "Deleting $file\n" if $verbose;
                        if (!$dry_run) {
                            unlink($file) or die "ERROR: could not unlink $file: $!\n";
                        }
                    }
                },
            }, @output_cgi_data_dirs);
            for my $dir (@output_cgi_data_dirs, ( ( any { $job_type eq $_ } qw( BCCA Germline TEMP ) ) ? $output_dataset_cgi_dir : () )) {
                if (-z $dir) {
                    print "Deleting $dir\n" if $verbose;
                    if (!$dry_run) {
                        remove_tree($dir, { error => \my $err });
                        if (@{$err}) {
                            for my $diag (@{$err}) {
                                my ($file, $message) = %{$diag};
                                if ($file eq '') {
                                    die "ERROR: could not delete $dir: $message";
                                }
                                else {
                                    die "ERROR: could not delete $file: $message";
                                }
                            }
                        }
                    }
                }
            }
        }
        next if $clean_only;
        if ($job_type eq 'FullMafsVcfs' or ($disease_proj eq 'OS' and $job_type eq 'SomaticVcfs')) {
            my @output_dirs = ($output_cgi_data_dirs[0]);
            if (!$dry_run) {
                for my $output_dir (@output_dirs) {
                    make_path($output_dir, {
                        chmod => $dir_mode,
                        owner => $owner_name,
                        group => $ctrld_group_name,
                        error => \my $err,
                    });
                    if (@{$err}) {
                        for my $diag (@{$err}) {
                            my ($file, $message) = %{$diag};
                            if ($file eq '') {
                                die "ERROR: could not create $output_dir: $message";
                            }
                            else {
                                die "ERROR: could not create $file: $message";
                            }
                        }
                    }
                }
            }
        }
        my %symlink_file_case_dir_name;
        my $links_created = 0;
        print "Searching for data and generating links\n";
        find({
            follow => 1,
            wanted => sub {
                # directories
                if (-d) {
                    my $dir_name = $_;
                    my $dir = $File::Find::name;
                    my $parent_dir = $File::Find::dir;
                    # skip "old_data" subdirectory trees
                    # skip "VCF_files_without_FET" subdirectory trees
                    if ($dir_name =~ /(old_data|VCF_files_without_FET)/i) {
                        print "Skipping $dir\n" if $verbose;
                        $File::Find::prune = 1;
                        return;
                    }
                    # TARGET case-named directories (with possible CGI numeric extension)
                    elsif ($dir_name =~ /^$CGI_CASE_DIR_REGEXP$/) {
                        # do nothing for now
                    }
                    # TARGET barcode-named directories
                    elsif ($dir_name =~ /^$BARCODE_REGEXP$/) {
                        my ($case_id, $disease_code, $tissue_type, $xeno_cell_line_code) = get_barcode_info($dir_name);
                        # Germline
                        if ($job_type eq 'Germline') {
                            # Germline aka 'Normal' directories and
                            # special case for OS CGI BCCA Primary/CellLine*/Xenograft* sample dirs
                            # symlink entire directory instead of particular files (below)
                            if (
                                $tissue_type =~ /Normal/ or 
                                (
                                    $disease_proj eq 'OS' and 
                                    $parent_dir !~ /\/EXP$/ and
                                    $tissue_type =~ /(Primary|CellLine|Xenograft)/
                                )
                            ) {
                                (my $output_dir = $parent_dir) =~ s/^\Q$dataset_cgi_dir\E/$output_dataset_cgi_dir/
                                    or die "\nERROR: bad path $parent_dir\n";
                                print "Creating $output_dir\n" if $verbose;
                                if (!$dry_run) {
                                    make_path($output_dir, {
                                        chmod => $dir_mode,
                                        owner => $owner_name,
                                        group => $group_name,
                                        error => \my $err,
                                    });
                                    if (@{$err}) {
                                        for my $diag (@{$err}) {
                                            my ($file, $message) = %{$diag};
                                            if ($file eq '') {
                                                die "ERROR: could not create $output_dir: $message";
                                            }
                                            else {
                                                die "ERROR: could not create $file: $message";
                                            }
                                        }
                                    }
                                }
                                my $dir_to_link_realpath = realpath($dir);
                                if ($verbose) {
                                    print "Linking $output_dir/$dir_name ->\n",
                                          "        $dir_to_link_realpath\n";
                                }
                                if (!$dry_run) {
                                    # check if symlink already exists
                                    if (!-e "$output_dir/$dir_name") {
                                        symlink($dir_to_link_realpath, "$output_dir/$dir_name")
                                            or die "ERROR: could not create symlink: $!\n",
                                                   "$output_dir/$dir_name ->\n",
                                                   "$dir_to_link_realpath\n";
                                        my $chown_cmd = "chown -h $owner_name:$owner_name $output_dir/$dir_name";
                                        #print "$chown_cmd\n" if $verbose;
                                        system($chown_cmd) == 0 or warn "ERROR: could not chown of symlink\n";
                                    }
                                    else {
                                        die "\nERROR: data link already exists for $output_dir/$dir_name\n\n";
                                    }
                                }
                                append_to_manifests($parent_dir, $output_dir, $dir_name);
                            }
                        }
                    }
                }
                # files
                elsif (-f) {
                    my $file_name = $_;
                    my $file = $File::Find::name;
                    my $file_dir = $File::Find::dir;
                    my @file_dir_parts = File::Spec->splitdir($file_dir);
                    my ($case_dir_name) = grep { m/^$CGI_CASE_DIR_REGEXP$/ } @file_dir_parts;
                    my $case_exp_dir_parts_idx;
                    if (
                        $disease_proj eq 'OS' and 
                        $file_dir !~ /(Pilot|Option)AnalysisPipeline2\/$case_dir_name\/EXP/
                    ) {
                        ($case_exp_dir_parts_idx) = grep { $file_dir_parts[$_] =~ /^$CGI_CASE_DIR_REGEXP$/ } 0 .. $#file_dir_parts;
                    }
                    else {
                        ($case_exp_dir_parts_idx) = grep { $file_dir_parts[$_] =~ /^EXP$/ } 0 .. $#file_dir_parts;
                    }
                    my $case_exp_dir = File::Spec->catdir(@file_dir_parts[0 .. $case_exp_dir_parts_idx]);
                    my ($barcode) = grep { m/^$BARCODE_REGEXP$/ } @file_dir_parts;
                    my ($barcode_dir_parts_idx) = grep { $file_dir_parts[$_] =~ /^$BARCODE_REGEXP$/ } 0 .. $#file_dir_parts;
                    # files under barcode directories
                    if (defined $barcode) {
                        my @file_dir_barcode_rel_parts = @file_dir_parts[$barcode_dir_parts_idx .. $#file_dir_parts];
                        my ($case_id, $disease_code, $tissue_type, $xeno_cell_line_code) = get_barcode_info($barcode);
                        # BCCA
                        if ($job_type eq 'BCCA') {
                            # full somaticVcfBeta MAF and VCF files
                            if (m/^somaticVcfBeta.+?(?:(?<!somatic)_maf_FET\.txt|\.vcf\.bz2)$/i) {
                                link_file(
                                    $dataset_cgi_dir, $output_dataset_cgi_dir, 
                                    $case_exp_dir, $file_dir, $file, $file_name,
                                    \@file_dir_barcode_rel_parts,
                                );
                                $links_created++;
                                if (!$verbose) {
                                    print "\b" x length("$links_created created"), $links_created, ' created';
                                }
                            }
                        }
                        # Germline
                        elsif ($job_type eq 'Germline') {
                            # Primary/CellLine/Xenograft full somaticVcfBeta MAF and masterVarBeta files
                            if (
                                $tissue_type =~ /(Primary|CellLine|Xenograft)/ and
                                m/^(?:somaticVcfBeta.+?(?<!somatic)_maf_FET\.txt|masterVarBeta.+?\.tsv\.bz2)$/i 
                            ) {
                                link_file(
                                    $dataset_cgi_dir, $output_dataset_cgi_dir, 
                                    $case_exp_dir, $file_dir, $file, $file_name,
                                    \@file_dir_barcode_rel_parts,
                                );
                                $links_created++;
                                if (!$verbose) {
                                    print "\b" x length("$links_created created"), $links_created, ' created';
                                }
                            }
                        }
                        # TEMP
                        elsif ($job_type eq 'TEMP') {
                            # masterVarBeta files
                            if (m/^masterVarBeta.+?\.tsv\.bz2$/i) {
                                link_file(
                                    $dataset_cgi_dir, $output_dataset_cgi_dir, 
                                    $case_exp_dir, $file_dir, $file, $file_name,
                                    \@file_dir_barcode_rel_parts,
                                );
                                $links_created++;
                                if (!$verbose) {
                                    print "\b" x length("$links_created created"), $links_created, ' created';
                                }
                            }
                        }
                        # FullMafsVcfs
                        elsif ($job_type eq 'FullMafsVcfs') {
                            my $output_dir = $output_cgi_data_dirs[0];
                            # full somaticVcfBeta MAF and VCF files
                            if (m/^somaticVcfBeta.+?(?:(?<!somatic)_maf_FET\.txt|\.vcf\.bz2)$/i) {
                                my $file_to_link_realpath = realpath($file);
                                my ($file_to_link_basename, $file_to_link_dir, $file_to_link_ext) = 
                                    fileparse($file_to_link_realpath, qr/\..*/);
                                my $symlink_file_prefix;
                                (my $symlink_file_ext = $file_to_link_ext) =~ s/^\.annotated_FET//;
                                if ($symlink_file_ext eq '.vcf.bz2') {
                                    $symlink_file_prefix = 'fullVcf';
                                }
                                elsif ($symlink_file_ext eq '.txt') {
                                    $symlink_file_prefix = 'fullMaf';
                                    $symlink_file_ext = '.maf.txt';
                                }
                                else {
                                    die "\nERROR: unkown file extension $file_to_link_ext\n\n";
                                }
                                # determine left "Vs" comparator
                                if ($file_dir_parts[$#file_dir_parts] ne 'ASM' or
                                    $file_dir_parts[$#file_dir_parts - 2] ne 'EXP') {
                                    die "\nERROR: invalid CGI sample directory path: $file_dir\n\n";
                                }
                                print STDERR "\$case_exp_dir:\n$case_exp_dir\n" if $debug;
                                my @other_sample_dirs = grep { 
                                    -d and 
                                    m/^\Q$case_exp_dir\E\/$BARCODE_REGEXP$/ and 
                                    $_ ne "$case_exp_dir/$file_dir_parts[$#file_dir_parts - 1]"
                                } glob("$case_exp_dir/*");
                                print STDERR "\@other_sample_dirs:\n", Dumper(\@other_sample_dirs) if $debug;
                                my $cmp_sample_dir;
                                if (scalar(@other_sample_dirs) > 1) {
                                    my @other_normal_sample_dirs;
                                    for my $other_sample_dir (@other_sample_dirs) {
                                        my @other_sample_dir_parts = File::Spec->splitdir($other_sample_dir);
                                        my $barcode = $other_sample_dir_parts[$#other_sample_dir_parts];
                                        if ((get_barcode_info($barcode))[2] =~ /Normal/) {
                                            push @other_normal_sample_dirs, $other_sample_dir;
                                        }
                                    }
                                    if (scalar(@other_normal_sample_dirs) == 1) {
                                        $cmp_sample_dir = $other_normal_sample_dirs[0];
                                    }
                                    else {
                                        die "\nERROR: could not determine comparator sample directory in $case_exp_dir\n\n";
                                    }
                                }
                                elsif (scalar(@other_sample_dirs) == 1) {
                                    $cmp_sample_dir = $other_sample_dirs[0];
                                }
                                else {
                                    die "\nERROR: sample directories missing in $case_exp_dir\n\n";
                                }
                                print STDERR "\$cmp_sample_dir:\n$cmp_sample_dir\n" if $debug;
                                if (!-d "$cmp_sample_dir/ASM") {
                                    die "\nERROR: invalid sample data directory: $cmp_sample_dir\n\n";
                                }
                                if (
                                    grep { -f and m/^\Q$cmp_sample_dir\E\/ASM\/somaticVcfBeta/i }
                                    glob("$cmp_sample_dir/ASM/*")
                                ) {
                                    die "\nERROR: comparator sample data directory contains somatic data: $cmp_sample_dir/ASM\n";
                                }
                                my @cmp_sample_dir_parts = File::Spec->splitdir($cmp_sample_dir);
                                my $cmp_barcode = $cmp_sample_dir_parts[$#cmp_sample_dir_parts];
                                my ($cmp_case_id, $cmp_disease_code, $cmp_tissue_type, $cmp_xeno_cell_line_code) = get_barcode_info($cmp_barcode);
                                my $symlink_file_name = 
                                    "${symlink_file_prefix}_${case_id}_" .
                                    $cmp_tissue_type . (defined $cmp_xeno_cell_line_code ? $cmp_xeno_cell_line_code : '') . 
                                    'Vs' .
                                    $tissue_type . (defined $xeno_cell_line_code ? $xeno_cell_line_code : '') .
                                    $symlink_file_ext;
                                my $link_add_text;
                                # check if symlink already exists (duplicate CGI) and update if necessary
                                if (-e "$output_dir/$symlink_file_name") {
                                    my $existing_file_realpath = realpath("$output_dir/$symlink_file_name");
                                    my $mtime_existing_file = (stat($existing_file_realpath))[9];
                                    my $mdate_existing_file = strftime('%Y-%m-%d %H:%M:%S', localtime($mtime_existing_file));
                                    my $mtime_new_file = (stat($file_to_link_realpath))[9];
                                    my $mdate_new_file = strftime('%Y-%m-%d %H:%M:%S', localtime($mtime_new_file));
                                    if ($mtime_new_file > $mtime_existing_file) {
                                        my $existing_case_dir_num_ext = 
                                            $symlink_file_case_dir_name{$symlink_file_name} =~ /(?:-|_)(\d+)$/ ? $1 : 0;
                                        my $new_case_dir_num_ext = $case_dir_name =~ /(?:-|_)(\d+)$/ ? $1 : 0;
                                        if ($new_case_dir_num_ext <= $existing_case_dir_num_ext) {
                                            warn "ERROR: new file to replace existing has lower case directory extension:\n",
                                                 "     new $file_to_link_realpath\n",
                                                 "         ($mdate_new_file)\n",
                                                 "existing $existing_file_realpath\n",
                                                 "         ($mdate_existing_file)\n";
                                            return;
                                        }
                                        if ($verbose) {
                                            print "Removing $output_dir/$symlink_file_name\n",
                                                  "        ($mdate_existing_file $symlink_file_case_dir_name{$symlink_file_name})\n";
                                        }
                                        if (!$dry_run) {
                                            unlink("$output_dir/$symlink_file_name")
                                                or die "\nERROR: could not unlink $output_dir/$symlink_file_name: $!\n\n";
                                        }
                                        $link_add_text = "$mdate_new_file $case_dir_name";
                                    }
                                    else {
                                        if ($verbose) {
                                            print "Skipping $file\n",
                                                  "         ($mdate_new_file $case_dir_name)\n",
                                                  "Existing $output_dir/$symlink_file_name\n",
                                                  "         ($mdate_existing_file $symlink_file_case_dir_name{$symlink_file_name})\n";
                                        }
                                        return;
                                    }
                                }
                                my $file_to_link_rel_path = File::Spec->abs2rel($file_to_link_realpath, $output_dir);
                                if ($verbose) {
                                    print "Linking $output_dir/$symlink_file_name ->\n",
                                          "        $file_to_link_rel_path\n",
                                          "       ($file)\n",
                                          $link_add_text ?
                                          "        ($link_add_text)\n"
                                                         :
                                          '';
                                }
                                if (!$dry_run) {
                                    symlink($file_to_link_rel_path, "$output_dir/$symlink_file_name")
                                        or die "\nERROR: could not create symlink: $!\n",
                                               " $output_dir/$symlink_file_name ->\n",
                                               " $file_to_link_rel_path\n",
                                               "($file)\n",
                                               $link_add_text ? 
                                               "($link_add_text)\n" 
                                                              : 
                                               '';
                                    my $chown_cmd = "chown -h $owner_name:$owner_name $output_dir/$symlink_file_name";
                                    #print "$chown_cmd\n" if $verbose;
                                    system($chown_cmd) == 0 or warn "ERROR: could not chown of symlink\n";
                                }
                                $links_created++;
                                if (!$verbose) {
                                    print "\b" x length("$links_created created"), $links_created, ' created';
                                }
                                $symlink_file_case_dir_name{$symlink_file_name} = $case_dir_name;
                            }
                            # OS CGI BCCA VCFs
                            elsif (
                                $disease_proj eq 'OS' and 
                                $file_dir !~ /(Pilot|Option)AnalysisPipeline2\/$case_dir_name\/EXP/ and
                                m/^.+?\.vcf\.bz2$/i
                            ) {
                                my $file_to_link_realpath = realpath($file);
                                my ($file_to_link_basename, $file_to_link_dir, $file_to_link_ext) = 
                                    fileparse($file_to_link_realpath, qr/\..*/);
                                my $symlink_file_prefix;
                                my $symlink_file_ext = $file_to_link_ext;
                                if ($symlink_file_ext eq '.vcf.bz2') {
                                    $symlink_file_prefix = 'fullVcf';
                                }
                                else {
                                    die "\nERROR: unkown file extension $file_to_link_ext\n\n";
                                }
                                my $symlink_file_name = 
                                    "${symlink_file_prefix}_${barcode}${symlink_file_ext}";
                                my $file_to_link_rel_path = File::Spec->abs2rel($file_to_link_realpath, $output_dir);
                                if ($verbose) {
                                    print "Linking $output_dir/$symlink_file_name ->\n",
                                          "        $file_to_link_rel_path\n",
                                          "       ($file)\n";
                                }
                                if (!$dry_run) {
                                    symlink($file_to_link_rel_path, "$output_dir/$symlink_file_name")
                                        or die "\nERROR: could not create symlink: $!\n",
                                               " $output_dir/$symlink_file_name ->\n",
                                               " $file_to_link_rel_path\n",
                                               "($file)\n";
                                    my $chown_cmd = "chown -h $owner_name:$owner_name $output_dir/$symlink_file_name";
                                    #print "$chown_cmd\n" if $verbose;
                                    system($chown_cmd) == 0 or warn "ERROR: could not chown of symlink\n";
                                }
                                $links_created++;
                                if (!$verbose) {
                                    print "\b" x length("$links_created created"), $links_created, ' created';
                                }
                            }
                        }
                    }
                    # files under OS CGI BCCA TumorVsNormal directories
                    elsif (
                        $disease_proj eq 'OS' and
                        $file_dir !~ /(Pilot|Option)AnalysisPipeline2\/$case_dir_name\/EXP/ and
                        $file_dir_parts[$#file_dir_parts] eq 'TumorVsNormal'
                    ) {
                        # SomaticVcfs
                        if ($job_type eq 'SomaticVcfs') {
                            # OS CGI BCCA somatic VCFs
                            if (m/^.+?\.vcf$/i) {
                                my $new_file = "$output_cgi_data_dirs[0]/somaticVcf_${case_dir_name}_NormalVsPrimary.vcf";
                                if ($verbose) {
                                    print "Copying $file ->\n",
                                          "        $new_file\n";
                                }
                                if (!$dry_run) {
                                    copy($file, $new_file) 
                                        or die "\nERROR: copy failed: $!\n",
                                               "$file ->\n",
                                               "$new_file\n";
                                    chown($owner_uid, $ctrld_group_gid, $new_file) or warn "ERROR: couldn't chown: $!\n";
                                    chmod($file_mode, $new_file) or warn "ERROR: couldn't chmod: $!\n";
                                }
                                $links_created++;
                                if (!$verbose) {
                                    print "\b" x length("$links_created created"), $links_created, ' created';
                                }
                            }
                        }
                    }
                    elsif (
                        none { $file =~ /^\Q$case_exp_dir\E\/$_$/ } (@target_cgi_manifest_file_names, @target_cgi_skip_file_names) and
                        $file !~ /^\Q$case_exp_dir\E\/README.*?\.txt$/
                    ) {
                        die "ERROR: unsupported file $file\n";
                    }
                }
            },
        }, @cgi_data_dirs);
        if ($verbose) {
            print "$links_created links created\n";
        }
        else {
            print "\n";
        }
    }
}
exit;

sub link_file {
    my (
        $dataset_cgi_dir, $output_dataset_cgi_dir, 
        $case_exp_dir, $file_dir, $file, $file_name,
        $file_dir_barcode_rel_parts_arrayref,
    ) = @_;
    (my $output_case_exp_dir = $case_exp_dir) =~ s/^\Q$dataset_cgi_dir\E/$output_dataset_cgi_dir/
        or die "\nERROR: bad path $case_exp_dir\n";
    (my $output_dir = $file_dir) =~ s/^\Q$dataset_cgi_dir\E/$output_dataset_cgi_dir/
        or die "\nERROR: bad path $file_dir\n";
    print "Creating $output_dir\n" if $verbose;
    if (!$dry_run) {
        make_path($output_dir, {
            chmod => $dir_mode,
            owner => $owner_name,
            group => $group_name,
            error => \my $err,
        });
        if (@{$err}) {
            for my $diag (@{$err}) {
                my ($file, $message) = %{$diag};
                if ($file eq '') {
                    die "ERROR: could not create $output_dir: $message";
                }
                else {
                    die "ERROR: could not create $file: $message";
                }
            }
        }
    }
    my $file_to_link_realpath = realpath($file);
    if ($verbose) {
        print "Linking $output_dir/$file_name ->\n",
              "        $file_to_link_realpath\n";
    }
    if (!$dry_run) {
        # check if symlink already exists
        if (!-e "$output_dir/$file_name") {
            symlink($file_to_link_realpath, "$output_dir/$file_name") 
                or die "\nERROR: could not create symlink: $!\n",
                       "$output_dir/$file_name ->\n",
                       "$file_to_link_realpath\n\n";
            my $chown_cmd = "chown -h $owner_name:$owner_name $output_dir/$file_name";
            #print "$chown_cmd\n" if $verbose;
            system($chown_cmd) == 0 or warn "ERROR: could not chown of symlink\n";
        }
        else {
            die "\nERROR: data link already exists for $output_dir/$file_name\n\n";
        }
    }
    my $file_barcode_rel_path = File::Spec->catdir(@{$file_dir_barcode_rel_parts_arrayref}, $file_name);
    append_to_manifests($case_exp_dir, $output_case_exp_dir, $file_barcode_rel_path);
}

sub get_barcode_info {
    my ($barcode) = @_;
    my ($case_id, $disease_code, $tissue_code);
    my @barcode_parts = split('-', $barcode);
    # TARGET sample ID/barcode
    if (scalar(@barcode_parts) == 5) {
        $case_id = join('-', @barcode_parts[0..2]);
        ($disease_code, $tissue_code) = @barcode_parts[1,3];
    }
    else {
        die "\nERROR: invalid sample ID/barcode $barcode\n\n";
    }
    ($tissue_code, my $xeno_cell_line_code) = split(/\./, $tissue_code);
    my $tissue_ltr = substr($tissue_code, -1);
    #$tissue_code =~ s/\D//g;
    $tissue_code = substr($tissue_code, 0, 2);
    my $tissue_type = $tissue_code eq '01' ? 'Primary' :
                      $tissue_code eq '02' ? 'Recurrent' :
                      $tissue_code eq '03' ? 'Primary' :
                      $tissue_code eq '04' ? 'Recurrent' :
                      $tissue_code eq '05' ? 'Primary' :
                      # 06 is actually Metastatic but Primary for this purpose
                      $tissue_code eq '06' ? 'Primary' :
                      $tissue_code eq '09' ? 'Primary' :
                      $tissue_code eq '10' ? 'Normal' :
                      $tissue_code eq '11' ? 'Normal' :
                      $tissue_code eq '12' ? 'BuccalNormal' :
                      $tissue_code eq '13' ? 'EBVNormal' :
                      $tissue_code eq '14' ? 'Normal' :
                      $tissue_code eq '15' ? 'NormalFibroblast' :
                      $tissue_code eq '16' ? 'Normal' :
                      $tissue_code eq '20' ? 'CellLineControl' : 
                      $tissue_code eq '40' ? 'Recurrent' :
                      $tissue_code eq '41' ? 'Recurrent' :
                      $tissue_code eq '42' ? 'Recurrent' : 
                      $tissue_code eq '50' ? 'CellLine' :
                      $tissue_code eq '60' ? 'Xenograft' :
                      $tissue_code eq '61' ? 'Xenograft' :
                      undef;
    die "\nERROR: unknown tissue code $tissue_code\n\n" unless defined $tissue_type;
    # special fix for TARGET-10-PANKMB
    if ($case_id eq 'TARGET-10-PANKMB' and $tissue_type eq 'Primary') {
        $tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-10-PAKKCA
    elsif ($case_id eq 'TARGET-10-PAKKCA' and $tissue_type eq 'Primary') {
        $tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-30-PARKGJ
    elsif ($case_id eq 'TARGET-30-PARKGJ' and ($tissue_type eq 'Primary' or $tissue_type eq 'Normal')) {
        $tissue_type .= $barcode_parts[$#barcode_parts];
    }
    # special fix for TARGET-50-PAKJGM
    elsif ($case_id eq 'TARGET-50-PAKJGM' and $tissue_type eq 'Normal') {
        $tissue_type .= $barcode_parts[$#barcode_parts];
    }
    return ($case_id, $disease_code, $tissue_type, $xeno_cell_line_code);
}

sub append_to_manifests {
    my ($manifest_in_dir, $manifest_out_dir, $file_search_str) = @_;
    my $found_in_manifests;
    for my $manifest_file_name (@target_cgi_manifest_file_names) {
        if (-f "$manifest_in_dir/$manifest_file_name") {
            my @manifest_lines;
            open(my $manifest_in_fh, '<', "$manifest_in_dir/$manifest_file_name")
                or die "\nERROR: could not open $manifest_in_dir/$manifest_file_name\n\n";
            while (<$manifest_in_fh>) {
                next if m/^\s*$/;
                my ($checksum, $file_path) = split(' ', $_, 2);
                if ($file_path =~ /^\*$file_search_str/) {
                    push @manifest_lines, $_;
                    $found_in_manifests++;
                }
            }
            close($manifest_in_fh);
            if (@manifest_lines) {
                if ($verbose) {
                    print "Appending to $manifest_out_dir/$manifest_file_name\n";
                }
                if (!$dry_run) {
                    open(my $manifest_out_fh, '>>', "$manifest_out_dir/$manifest_file_name")
                        or die "\nERROR: could not open $manifest_out_dir/$manifest_file_name\n\n";
                    print $manifest_out_fh @manifest_lines;
                    close($manifest_out_fh);
                }
                if ($verbose) {
                    print "Sorting $manifest_out_dir/$manifest_file_name\n";
                }
                if (!$dry_run) {
                    open(my $manifest_in_fh, '<', "$manifest_out_dir/$manifest_file_name")
                        or die "\nERROR: could not read open $manifest_out_dir/$manifest_file_name\n\n";
                    my @manifest_lines = <$manifest_in_fh>;
                    close($manifest_in_fh);
                    my @sorted_manifest_lines = sort manifest_by_file_path @manifest_lines;
                    open(my $manifest_out_fh, '>', "$manifest_out_dir/$manifest_file_name")
                        or die "\nERROR: could not write open $manifest_out_dir/$manifest_file_name\n\n";
                    print $manifest_out_fh @sorted_manifest_lines;
                    close($manifest_out_fh);
                }
            }
        }
        elsif ($manifest_in_dir !~ /\/EXP$/) {
            die "\nERROR: $manifest_in_dir/$manifest_file_name missing\n\n";
        }
    }
    if (!$found_in_manifests and $manifest_in_dir !~ /\/EXP$/) {
        warn "\nERROR: $file_search_str not found in manifests\n\n";
    }
}

__END__

=head1 NAME 

generate_target_cgi_special_datasets.pl - TARGET CGI Special Dataset Generator

=head1 SYNOPSIS

 generate_target_cgi_special_datasets.pl [options] <type> <proj 1>,<proj 2>,...,<proj n>
 
 Parameters:
    <type>                              Special dataset job type (required: one of BCCA, Germline, FullMafsVcfs, SomaticVcfs, TEMP)
    <proj 1>,<proj 2>,...,<proj n>      Disease project code(s) (optional: default all disease projects)
 
 Options:
    --verbose                           Be verbose
    --dry-run                           Show what would be done
    --clean-only                        Clean up existing dataset only and then exit
    --debug                             Show debug information
    --help                              Display usage message and exit
    --version                           Display program version and exit

=cut

