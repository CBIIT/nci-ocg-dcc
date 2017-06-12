#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use File::Path 2.11 qw( make_path );
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any first none uniq );
use NCI::OCGDCC::Utils qw( load_configs );
use Pod::Usage qw( pod2usage );
use Sort::Key::Natural qw( natsort );
use Term::ANSIColor;
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams
# (make sure STDOUT is last so that it remains the default filehandle)
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
my %program_subproject_names = %{$config_hashref->{'cgi'}->{'program_subproject_names'}};
my (
    $adm_owner_name,
    $adm_group_name,
    $dn_ctrld_group_name,
    $dn_ctrld_dir_mode,
    $dn_ctrld_dir_mode_str,
    $dn_ctrld_file_mode,
    $dn_ctrld_file_mode_str,
) = @{$config_hashref->{'cgi'}->{'data_filesys_info'}}{qw(
    adm_owner_name
    adm_group_name
    dn_ctrld_group_name
    dn_ctrld_dir_mode
    dn_ctrld_dir_mode_str
    dn_ctrld_file_mode
    dn_ctrld_file_mode_str
)};
my @param_groups = qw(
    programs
    projects
);

my $dry_run = 0;
my $clean_only = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'dry-run' => \$dry_run,
    'clean-only' => \$clean_only,
    'verbose' => \$verbose,
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
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    my $program_data_dir = "/local/ocg-dcc/data/\U$program_name\E";
    my $program_download_ctrld_dir = "/local/ocg-dcc/download/\U$program_name\E/Controlled";
    my $symlink_file = "$FindBin::Bin/\L$program_name\E_cgi_data_symlinks.txt";
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
        print "[$program_name $project_name]\n";
        my $subproject_regexp_str = join('|', @{$program_subproject_names{$program_name}});
        my ($disease_proj, $subproject) = split /-(?=$subproject_regexp_str)/, $project_name, 2;
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
        open(my $fh, '<', $symlink_file) or
            die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                ": could not open $symlink_file: $!";
        while (<$fh>) {
            s/^\s+//;
            s/\s+$//;
            my ($target, $link) = split /\t/;
            if (!-d $target) {
                warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                     ": $target doesn't exist\n";
            }
            my @link_dir_parts = File::Spec->splitdir($link);
            my $link_parent_dir = File::Spec->catdir(@link_dir_parts[0 .. $#link_dir_parts - 1]);
            if (!-d $link_parent_dir) {
                print "Creating $link_parent_dir\n";
                if (!$dry_run) {
                    make_path($link_parent_dir, {
                        chmod => $dn_ctrld_dir_mode,
                        owner => $adm_owner_name,
                        group => $adm_group_name,
                        error => \my $err,
                    });
                    if (@{$err}) {
                        for my $diag (@{$err}) {
                            my ($file, $message) = %{$diag};
                            warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                                 ": could not create $file: $message\n";
                        }
                    }
                }
            }
            if (-e $link) {
                print "Removing $link\n";
                if (!$dry_run) {
                    if (!unlink($link)) {
                        warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                             ": could not remove symlink: $!\n";
                        next;
                    }
                }
            }
            next if $clean_only;
            my $target_rel_path = File::Spec->abs2rel($target, $link_parent_dir);
            print "Linking $link ->\n",
                  "        $target_rel_path\n";
            if (!$dry_run) {
                symlink($target_rel_path, $link) or
                    warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                         ": could not create symlink: $!\n";
                system("chown -h $adm_owner_name:$adm_group_name $link") == 0 or
                    warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                         ": could not chown symlink, exit code: ", $? >> 8, "\n";
            }
        }
        close($fh);
    }
}
exit;

__END__

=head1 NAME

create_cgi_data_symlinks.pl - CGI WGS Data Symlink Creator

=head1 SYNOPSIS

 create_cgi_data_symlinks.pl <program name(s)> <project name(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
 
 Options:
    --dry-run               Perform trial run with no changes made (doesn't require sudo)
    --clean-only            Only clean existing links
    --verbose               Be verbose
    --help                  Display usage message and exit
    --version               Display program version and exit
 
=cut
