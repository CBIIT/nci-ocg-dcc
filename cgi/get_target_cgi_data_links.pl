#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd qw(realpath);
use File::Find;
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw( any none );
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natkeysort);
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

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
my $target_download_ctrld_dir = '/local/ocg-dcc/download/TARGET/Controlled';
my $data_type_dir_name = 'WGS';
my $cgi_dir_name = 'CGI';
my @target_cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);
my @param_groups = qw(
    projects
);

my $relative = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'relative' => \$relative,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/;
        my (@valid_user_params, @invalid_user_params, @valid_choices);
        my @user_params = split(',', $ARGV[$i]);
        if ($param_groups[$i] eq 'projects') {
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
for my $project_name (@project_names) {
    next if defined $user_params{projects} and none { $project_name eq $_ } @{$user_params{projects}};
    print "[$project_name]\n";
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
    my @cgi_data_dirs;
    for my $data_dir_name (@target_cgi_data_dir_names) {
        my $cgi_data_dir = "$dataset_cgi_dir/$data_dir_name";
        push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
    }
    if ($debug) {
        print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs);
    }
    my @link_info;
    find({
        wanted => sub {
            # symlinks only
            return unless -l;
            my $link = $File::Find::name;
            my $link_dir = $File::Find::dir;
            my $target = realpath(readlink($link));
            if ($relative) {
                $target = File::Spec->abs2rel($target, $link_dir);
            }
            push @link_info, [
                $target,
                $link,
            ];
        },
    }, @cgi_data_dirs);
    print join("\n", map { "$_->[0]\t$_->[1]" } natkeysort { $_->[1] } @link_info), "\n";
}

__END__

=head1 NAME 

get_target_cgi_data_links.pl - TARGET CGI Data Symlink List

=head1 SYNOPSIS

 get_target_cgi_data_links.pl [options] <proj 1>,<proj 2>,...,<proj n>
 
 Parameters:
    <proj 1>,<proj 2>,...,<proj n>      Disease project code(s) (optional: default all disease projects)
 
 Options:
    --relative          List relative links                     
    --verbose           Be verbose
    --debug             Show debug information
    --help              Display usage message and exit
    --version           Display program version and exit

=cut

