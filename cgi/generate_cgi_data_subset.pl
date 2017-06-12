#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use File::Basename qw( fileparse );
use File::Copy qw( copy );
use File::Find;
use File::Path 2.11 qw( make_path remove_tree );
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any first none uniq );
use NCI::OCGDCC::Config qw( :all );
use NCI::OCGDCC::Utils qw( load_configs );
use Pod::Usage qw( pod2usage );
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
my %program_project_names_w_subprojects = %{$config_hashref->{'cgi'}->{'program_project_names_w_subprojects'}};
my $data_type_dir_name = $config_hashref->{'cgi'}->{'data_type_dir_name'};
my $cgi_dir_name = $config_hashref->{'cgi'}->{'dir_name'};
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
my @param_groups = qw(
    programs
    projects
    cog_param
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
my %cog_ids;
if (!$clean_only) {
    pod2usage(
        -message => 'Comma-separated list of COG IDs or COG ID file required',
        -verbose => 0,
    ) unless defined $user_params{cog_param};
    if (
        scalar(@{$user_params{cog_param}}) == 1 and
        -f $user_params{cog_param}[0]
    ) {
        open(my $in_fh, '<', $user_params{cog_param}[0])
            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": $!";
        while (<$in_fh>) {
            s/\s+//g;
            $cog_ids{$_}++;
        }
        close($in_fh);
    }
    else {
        %cog_ids = map { s/\s+//g; $_ => 1 } @{$user_params{cog_param}}
    }
    print STDERR "\%cog_ids:\n", Dumper(\%cog_ids) if $debug;
}
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    my $program_data_dir = "/local/ocg-dcc/data/\U$program_name\E";
    my $program_download_ctrld_dir = "/local/ocg-dcc/download/\U$program_name\E/Controlled";
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
        print "[$program_name $project_name]\n";
        my ($disease_proj, $subproject);
        if (any { $project_name eq $_ } @{$program_project_names_w_subprojects{$program_name}}) {
            ($disease_proj, $subproject) = split /-/, $project_name, 2;
        }
        else {
            $disease_proj = $project_name;
        }
        my $project_dir = $disease_proj;
        if (defined($subproject)) {
            $project_dir = "$project_dir/$subproject";
        }
        my $data_type_dir = "$program_data_dir/$project_dir/$data_type_dir_name/current";
        my $dataset_dir_name = $project_name eq 'ALL'
                             ? 'Phase1+2'
                             : '';
        my $dataset_dir = $dataset_dir_name
                        ? "$data_type_dir/$dataset_dir_name"
                        : $data_type_dir;
        print "Using $dataset_dir\n";
        (my $dataset_download_ctrld_dir = $dataset_dir) =~ s/data/download\/Controlled/;
        $dataset_download_ctrld_dir =~ s/\/current//;
        (my $dataset_download_public_dir = $dataset_dir) =~ s/data/download\/Public/;
        $dataset_download_public_dir =~ s/\/current//;
        print "Cleaning dataset download dirs\n";
        for my $download_dir ($dataset_download_ctrld_dir, $dataset_download_public_dir) {
            my $rm_cmd_str = "rm -rf $download_dir";
            print "$rm_cmd_str\n";
            if (!$dry_run) {
                system(split(' ', $rm_cmd_str)) == 0 or die "ERROR: cmd failed: ", $? >> 8;
            }
        }
        exit if $clean_only;
        print "Filtering for cases: ", join(',', sort keys %cog_ids), "\n";
        print "Scanning dataset for case data\n";
        find({
            follow => 1,
            follow_skip => 2,
            wanted => sub {
                # directories
                if (-d) {
                    my $dir_name = $_;
                    my $dir = $File::Find::name;
                    my $parent_dir = $File::Find::dir;
                    # CGI case data directories
                    if (my ($case_id) = $dir =~ /(?:Pilot|Option)AnalysisPipeline2\/($OCG_CASE_REGEXP)/) {
                        if ($cog_ids{(split('-', $case_id))[2]}) {
                            if (-l $dir) {
                                (my $download_parent_dir = $parent_dir) =~ s/data/download\/Controlled/;
                                $download_parent_dir =~ s/\/current//;
                                if (!-e $download_parent_dir and !$dry_run) {
                                    print "Creating $download_parent_dir\n";
                                    make_path($download_parent_dir, {
                                        chmod => 0750,
                                        owner => $adm_owner_name,
                                        group => $dn_ctrld_group_name,
                                    });
                                }
                                print "Linking $download_parent_dir/$dir_name ->\n",
                                      "        ", readlink($dir), "\n";
                                if (!$dry_run) {
                                    symlink(readlink($dir), "$download_parent_dir/$dir_name") or warn "ERROR: symlink failed: $!\n";
                                }
                            }
                            else {
                                die "ERROR: should be symlink: $dir";
                            }
                        }
                        $File::Find::prune = 1;
                        return;
                    }
                    # skip Analysis and Junctions directories for now
                    elsif ($dir_name eq 'Analysis' or $dir_name eq 'Junctions') {
                        $File::Find::prune = 1;
                        return;
                    }
                    # DCC CGI data directories
                    elsif ($dir =~ /current\/L\d\/.+?\/CGI/) {
                        if (-l $dir) {
                            my $is_ctrld = $dir !~ /(circos|copy_number)/ ? 1 : 0;
                            my $download_parent_dir = $parent_dir;
                            if ($is_ctrld) {
                                $download_parent_dir =~ s/data/download\/Controlled/;
                            }
                            else {
                                $download_parent_dir =~ s/data/download\/Public/;
                            }
                            $download_parent_dir =~ s/\/current//;
                            if (!-e $download_parent_dir and !$dry_run) {
                                print "Creating $download_parent_dir\n";
                                make_path($download_parent_dir, {
                                    chmod => $is_ctrld ? 0750 : 0755,
                                    owner => $adm_owner_name,
                                    group => $is_ctrld ? $dn_ctrld_group_name : $dn_adm_group_name,
                                });
                            }
                            print "Linking $download_parent_dir/$dir_name ->\n",
                                  "        ", readlink($dir), "\n";
                            if (!$dry_run) {
                                symlink(readlink($dir), "$download_parent_dir/$dir_name") or warn "ERROR: symlink failed: $!\n";
                            }
                        }
                    }
                }
                elsif (-f) {
                    my $file_name = $_;
                    my $file = $File::Find::name;
                    my $parent_dir = $File::Find::dir;
                    if (my ($case_id) = $file_name =~ /($OCG_CASE_REGEXP)/) {
                        if ($cog_ids{(split('-', $case_id))[2]}) {
                            my $is_ctrld = $parent_dir !~ /CGI\/(Circos|CopyNumber)/ ? 1 : 0;
                            my $download_parent_dir = $parent_dir;
                            if ($is_ctrld) {
                                $download_parent_dir =~ s/data/download\/Controlled/;
                            }
                            else {
                                $download_parent_dir =~ s/data/download\/Public/;
                            }
                            $download_parent_dir =~ s/\/current//;
                            if (!-e $download_parent_dir and !$dry_run) {
                                print "Creating $download_parent_dir\n";
                                make_path($download_parent_dir, {
                                    chmod => $is_ctrld ? 0750 : 0755,
                                    owner => $adm_owner_name,
                                    group => $is_ctrld ? $dn_ctrld_group_name : $dn_adm_group_name,
                                });
                            }
                            if (-l $file) {
                                print "Linking $download_parent_dir/$file_name ->\n",
                                      "        ", readlink($file), "\n";
                                if (!$dry_run) {
                                    symlink(readlink($file), "$download_parent_dir/$file_name") or warn "ERROR: symlink failed: $!\n";
                                }
                            }
                            else {
                                print "Copying $file ->\n",
                                      "        $download_parent_dir/$file_name\n";
                                if (!$dry_run) {
                                    copy($file, "$download_parent_dir/$file_name") or warn "ERROR: copy failed: $!\n";
                                }
                            }
                        }
                    }
                    elsif ($file =~ /METADATA\/MAGE-TAB.+?\.(idf|sdrf)\.txt$/) {
                        (my $download_parent_dir = $parent_dir) =~ s/data/download\/Public/;
                        $download_parent_dir =~ s/\/current//;
                        if (!-e $download_parent_dir and !$dry_run) {
                            print "Creating $download_parent_dir\n";
                            make_path($download_parent_dir, {
                                chmod => 0755,
                                owner => $adm_owner_name,
                                group => $dn_adm_group_name,
                            });
                        }
                        if ($file_name =~ /\.idf\.txt$/) {
                            print "Copying $file ->\n",
                                  "        $download_parent_dir/$file_name\n";
                            if (!$dry_run) {
                                copy($file, "$download_parent_dir/$file_name") or warn "ERROR: copy failed: $!\n";
                            }
                        }
                        else {
                            print "Filtering $file\n";
                            my @filtered_sdrf_lines;
                            open(my $sdrf_in_fh, '<', $file)
                                or die "ERROR: could not read-open: $!\n";
                            my $col_header_line = <$sdrf_in_fh>;
                            push @filtered_sdrf_lines, $col_header_line;
                            while (<$sdrf_in_fh>) {
                                my @fields = split /\t/;
                                if ($cog_ids{(split('-', $fields[0]))[2]}) {
                                    push @filtered_sdrf_lines, $_;
                                }
                            }
                            close($sdrf_in_fh);
                            print "Creating $download_parent_dir/$file_name\n";
                            if (!$dry_run) {
                                open(my $sdrf_out_fh, '>', "$download_parent_dir/$file_name")
                                    or die "ERROR: could not write-open: $!\n";
                                print $sdrf_out_fh @filtered_sdrf_lines;
                                close($sdrf_out_fh);
                            }
                        }
                    }
                }
            },
        },
        $dataset_dir);
        my $rmdir_ctrld_cmd_str       = "find $dataset_download_ctrld_dir -depth -type d -empty -exec rmdir -v {} \\;";
        my $rmdir_public_cmd_str      = "find $dataset_download_public_dir -depth -type d -empty -exec rmdir -v {} \\;";
        my $dir_chmod_ctrld_cmd_str   = "find $dataset_download_ctrld_dir -type d -exec chmod 0550 {} \\;";
        my $dir_chmod_public_cmd_str  = "find $dataset_download_public_dir -type d -exec chmod 0555 {} \\;";
        my $file_chmod_ctrld_cmd_str  = "find $dataset_download_ctrld_dir -type f -exec chmod 0440 {} \\;";
        my $file_chmod_public_cmd_str = "find $dataset_download_public_dir -type f -exec chmod 0444 {} \\;";
        my $chown_ctrld_cmd_str       = "chown -R $adm_owner_name:$dn_ctrld_group_name $dataset_download_ctrld_dir";
        my $chown_public_cmd_str      = "chown -R $adm_owner_name:$dn_adm_group_name $dataset_download_public_dir";
        for my $cmd_str (
            $rmdir_ctrld_cmd_str, $rmdir_public_cmd_str,
            $dir_chmod_ctrld_cmd_str, $dir_chmod_public_cmd_str,
            $file_chmod_ctrld_cmd_str, $file_chmod_public_cmd_str,
            $chown_ctrld_cmd_str, $chown_public_cmd_str,
        ) {
            $cmd_str =~ s/\s+/ /g;
            print "$cmd_str\n";
            if (!$dry_run) {
                system($cmd_str) == 0
                    or warn "ERROR: command failed, exit code: ", $? >> 8, "\n";
            }
        }
    }
}
exit;

__END__

=head1 NAME

generate_cgi_data_subset.pl - CGI WGS Data Subset Generator

=head1 SYNOPSIS

 generate_cgi_data_subset.pl <program name(s)> <project name(s)> <cog id(s)> | <cog file> [options]
 
 Parameters:
    <program name(s)>           Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>           Comma-separated list of project name(s) (optional, default: all program projects)
    <cog id(s) | <cog file>     Comma-separated list of COG IDs or txt file with list of COG IDs (required)
 
 Options:
    --verbose                   Be verbose
    --dry-run                   Show what would be done
    --clean-only                Clean up existing dataset in public/controlled access areas and exit
    --debug                     Show debug information
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
