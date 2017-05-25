#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Cwd qw( realpath );
use File::Basename qw( fileparse );
use File::Copy qw( copy );
use File::Find;
use File::Path 2.11 qw( make_path remove_tree );
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any first none uniq );
use NCI::OCGDCC::Config qw( :all );
use NCI::OCGDCC::Utils qw( load_configs get_barcode_info manifest_by_file_path );
use Pod::Usage qw( pod2usage );
use POSIX qw( strftime );
use Sort::Key::Natural qw( natsort );
use Term::ANSIColor;
use Data::Dumper;

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
));
# use cgi (not common) program names and program project names
my @program_names = @{$config_hashref->{'cgi'}->{'program_names'}};
my %program_project_names = %{$config_hashref->{'cgi'}->{'program_project_names'}};
my @job_types = @{$config_hashref->{'cgi'}->{'job_types'}};
my $data_type_dir_name = $config_hashref->{'cgi'}->{'data_type_dir_name'};
my $cgi_dir_name = $config_hashref->{'cgi'}->{'dir_name'};
my @cgi_analysis_dir_names = @{$config_hashref->{'cgi'}->{'analysis_dir_names'}};
my @cgi_manifest_file_names = @{$config_hashref->{'cgi'}->{'manifest_file_names'}};
my @cgi_skip_file_names = @{$config_hashref->{'cgi'}->{'skip_file_names'}};
my (
    $adm_owner_name,
    $dn_adm_group_name,
    $dn_ctrld_group_name,
    $dn_ctrld_dir_mode,
    $dn_ctrld_file_mode,
) = @{$config_hashref->{'cgi'}->{'data_filesys_info'}}{qw(
    adm_owner_name
    dn_adm_group_name
    dn_ctrld_group_name
    dn_ctrld_dir_mode
    dn_ctrld_file_mode
)};
my $default_manifest_file_name = $config_hashref->{'manifests'}->{'default_manifest_file_name'};
my @param_groups = qw(
    programs
    projects
    job_types
);

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
        elsif ($param_groups[$i] eq 'job_types') {
            for my $job_type (@job_types) {
                push @valid_user_params, $job_type if any { m/^$job_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @job_types;
            }
            @valid_choices = @job_types;
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
my $adm_owner_uid = getpwnam($adm_owner_name)
    or die "ERROR: couldn't get uid for $adm_owner_name: $!\n";
my $dn_ctrld_group_gid = getgrnam($dn_ctrld_group_name)
    or die "ERROR: couldn't get gid for $dn_ctrld_group_name\n";
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    my $manifest_download_gid = getgrnam("\L$program_name\E-dn-adm")
        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": couldn't get gid for \L$program_name\E-dn-adm\n";
    my $program_data_dir = "/local/ocg-dcc/data/\U$program_name\E";
    my $program_download_ctrld_dir = "/local/ocg-dcc/download/\U$program_name\E/Controlled";
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
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
        my $data_type_dir = "$program_download_ctrld_dir/$project_dir/$data_type_dir_name";
        for my $job_type (@job_types) {
            next if defined $user_params{job_types} and none { $job_type eq $_ } @{$user_params{job_types}};
            print "[$program_name $project_name $job_type]\n";
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
                                        ? "$program_data_dir/$job_type/$project_dir/$data_type_dir_name/$dataset_dir_name/current/$cgi_dir_name"
                                        : "$program_data_dir/$job_type/$project_dir/$data_type_dir_name/current/$cgi_dir_name";
            }
            my (@cgi_analysis_dirs, @output_cgi_analysis_dirs);
            for my $analysis_dir_name (@cgi_analysis_dir_names) {
                my $cgi_analysis_dir = "$dataset_cgi_dir/$analysis_dir_name";
                push @cgi_analysis_dirs, $cgi_analysis_dir if -d $cgi_analysis_dir;
                my $output_cgi_analysis_dir = $job_type eq 'FullMafsVcfs'
                                        ? $dataset_dir_name
                                            ? "$program_download_ctrld_dir/$project_dir/$data_type_dir_name/$dataset_dir_name/L3/mutation/$cgi_dir_name/$job_type"
                                            : "$program_download_ctrld_dir/$project_dir/$data_type_dir_name/L3/mutation/$cgi_dir_name/$job_type"
                                        : $job_type eq 'SomaticVcfs'
                                        ? $dataset_dir_name
                                            ? "$program_data_dir/$project_dir/$data_type_dir_name/$dataset_dir_name/current/L3/mutation/$cgi_dir_name/$job_type"
                                            : "$program_data_dir/$project_dir/$data_type_dir_name/current/L3/mutation/$cgi_dir_name/$job_type"
                                        : "$output_dataset_cgi_dir/$analysis_dir_name";
                if (none { $_ eq $output_cgi_analysis_dir } @output_cgi_analysis_dirs) {
                    push @output_cgi_analysis_dirs, $output_cgi_analysis_dir;
                }
            }
            if ($debug) {
                print STDERR "\@cgi_analysis_dirs:\n", Dumper(\@cgi_analysis_dirs),
                             "\@output_cgi_analysis_dirs:\n", Dumper(\@output_cgi_analysis_dirs);
            }
            # clean existing datasets
            if (grep { -d } @output_cgi_analysis_dirs) {
                print "Removing existing datasets:\n",
                      join("\n", @output_cgi_analysis_dirs), "\n";
                find({
                    bydepth => 1,
                    preprocess => sub {
                        natsort @_;
                    },
                    wanted => sub {
                        if (-d) {
                            my $dir_name = $_;
                            my $dir = $File::Find::name;
                            if (( none { $dir eq $_ } @output_cgi_analysis_dirs ) and -z $dir) {
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
                }, @output_cgi_analysis_dirs);
                for my $dir (@output_cgi_analysis_dirs, ( ( any { $job_type eq $_ } qw( BCCA Germline TEMP ) ) ? $output_dataset_cgi_dir : () )) {
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
                my @output_dirs = ($output_cgi_analysis_dirs[0]);
                if (!$dry_run) {
                    for my $output_dir (@output_dirs) {
                        make_path($output_dir, {
                            chmod => $dn_ctrld_dir_mode,
                            owner => $adm_owner_name,
                            group => $dn_ctrld_group_name,
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
                        elsif ($dir_name =~ /^$OCG_CGI_CASE_DIR_REGEXP$/) {
                            # do nothing for now
                        }
                        # TARGET barcode-named directories
                        elsif ($dir_name =~ /^$OCG_BARCODE_REGEXP$/) {
                            my (
                                $case_id,
                                $disease_code,
                                $tissue_type,
                                $xeno_cell_line_code,
                            ) = @{get_barcode_info($dir_name)}{qw(
                                case_id
                                disease_code
                                cgi_tissue_type
                                xeno_cell_line_code
                            )};
                            # Germline
                            if ($job_type eq 'Germline') {
                                # Germline aka 'Normal' directories and
                                # special case for OS CGI BCCA Primary/CellLine*/Xenograft* sample dirs
                                # symlink entire directory instead of particular files (below)
                                if (
                                    $tissue_type =~ /Normal/i or
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
                                            chmod => $dn_ctrld_dir_mode,
                                            owner => $adm_owner_name,
                                            group => $dn_adm_group_name,
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
                                            my $chown_cmd = "chown -h $adm_owner_name:$adm_owner_name $output_dir/$dir_name";
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
                        my ($case_dir_name) = grep { m/^$OCG_CGI_CASE_DIR_REGEXP$/ } @file_dir_parts;
                        my $case_exp_dir_parts_idx;
                        if (
                            $disease_proj eq 'OS' and
                            $file_dir !~ /(Pilot|Option)AnalysisPipeline2\/$case_dir_name\/EXP/
                        ) {
                            ($case_exp_dir_parts_idx) = grep { $file_dir_parts[$_] =~ /^$OCG_CGI_CASE_DIR_REGEXP$/ } 0 .. $#file_dir_parts;
                        }
                        else {
                            ($case_exp_dir_parts_idx) = grep { $file_dir_parts[$_] =~ /^EXP$/ } 0 .. $#file_dir_parts;
                        }
                        my $case_exp_dir = File::Spec->catdir(@file_dir_parts[0 .. $case_exp_dir_parts_idx]);
                        my ($barcode) = grep { m/^$OCG_BARCODE_REGEXP$/ } @file_dir_parts;
                        my ($barcode_dir_parts_idx) = grep { $file_dir_parts[$_] =~ /^$OCG_BARCODE_REGEXP$/ } 0 .. $#file_dir_parts;
                        # files under barcode directories
                        if (defined $barcode) {
                            my @file_dir_barcode_rel_parts = @file_dir_parts[$barcode_dir_parts_idx .. $#file_dir_parts];
                            my (
                                $case_id,
                                $disease_code,
                                $tissue_type,
                                $xeno_cell_line_code,
                            ) = @{get_barcode_info($barcode)}{qw(
                                case_id
                                disease_code
                                cgi_tissue_type
                                xeno_cell_line_code
                            )};
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
                                my $output_dir = $output_cgi_analysis_dirs[0];
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
                                        m/^\Q$case_exp_dir\E\/$OCG_BARCODE_REGEXP$/ and
                                        $_ ne "$case_exp_dir/$file_dir_parts[$#file_dir_parts - 1]"
                                    } glob("$case_exp_dir/*");
                                    print STDERR "\@other_sample_dirs:\n", Dumper(\@other_sample_dirs) if $debug;
                                    my $cmp_sample_dir;
                                    if (scalar(@other_sample_dirs) > 1) {
                                        my @other_normal_sample_dirs;
                                        for my $other_sample_dir (@other_sample_dirs) {
                                            my @other_sample_dir_parts = File::Spec->splitdir($other_sample_dir);
                                            my $barcode = $other_sample_dir_parts[$#other_sample_dir_parts];
                                            if (get_barcode_info($barcode)->{cgi_tissue_type} =~ /Normal/i) {
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
                                    my (
                                        $cmp_case_id,
                                        $cmp_disease_code,
                                        $cmp_tissue_type,
                                        $cmp_xeno_cell_line_code,
                                    ) = @{get_barcode_info($cmp_barcode)}{qw(
                                        case_id
                                        disease_code
                                        cgi_tissue_type
                                        xeno_cell_line_code
                                    )};
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
                                        my $chown_cmd = "chown -h $adm_owner_name:$adm_owner_name $output_dir/$symlink_file_name";
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
                                        my $chown_cmd = "chown -h $adm_owner_name:$adm_owner_name $output_dir/$symlink_file_name";
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
                                    my $new_file = "$output_cgi_analysis_dirs[0]/somaticVcf_${case_dir_name}_NormalVsPrimary.vcf";
                                    if ($verbose) {
                                        print "Copying $file ->\n",
                                              "        $new_file\n";
                                    }
                                    if (!$dry_run) {
                                        copy($file, $new_file)
                                            or die "\nERROR: copy failed: $!\n",
                                                   "$file ->\n",
                                                   "$new_file\n";
                                        chown($adm_owner_uid, $dn_ctrld_group_gid, $new_file) or warn "ERROR: couldn't chown: $!\n";
                                        chmod($dn_ctrld_file_mode, $new_file) or warn "ERROR: couldn't chmod: $!\n";
                                    }
                                    $links_created++;
                                    if (!$verbose) {
                                        print "\b" x length("$links_created created"), $links_created, ' created';
                                    }
                                }
                            }
                        }
                        elsif (
                            none { $file =~ /^\Q$case_exp_dir\E\/$_$/ } (@cgi_manifest_file_names, @cgi_skip_file_names) and
                            $file !~ /^\Q$case_exp_dir\E\/README.*?\.txt$/
                        ) {
                            die "ERROR: unsupported file $file\n";
                        }
                    }
                },
            }, @cgi_analysis_dirs);
            if ($verbose) {
                print "$links_created links created\n";
            }
            else {
                print "\n";
            }
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
            chmod => $dn_ctrld_dir_mode,
            owner => $adm_owner_name,
            group => $dn_adm_group_name,
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
            my $chown_cmd = "chown -h $adm_owner_name:$adm_owner_name $output_dir/$file_name";
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

sub append_to_manifests {
    my ($manifest_in_dir, $manifest_out_dir, $file_search_str) = @_;
    my $found_in_manifests;
    for my $manifest_file_name (@cgi_manifest_file_names) {
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

generate_cgi_special_datasets.pl - CGI WGS Special Dataset Generator

=head1 SYNOPSIS

 generate_cgi_special_datasets.pl <program name(s)> <project name(s)> <job type(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
    <job type(s)>           Comma-separated list of job type(s) (optional, default: all job types)
 
 Options:
    --verbose               Be verbose
    --dry-run               Show what would be done
    --clean-only            Clean up existing dataset only and then exit
    --debug                 Show debug information
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut

