#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use File::Find;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any first none uniq );
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
my @cgi_analysis_dir_names = @{$config_hashref->{'cgi'}->{'analysis_dir_names'}};
my @param_groups = qw(
    programs
    projects
    cases
);

my $no_cell_lines_xenos = 0;
my $cell_lines_xenos_only = 0;
my $cases_only = 0;
my $debug = 0;
GetOptions(
    'no-cell-lines-xenos' => \$no_cell_lines_xenos,
    'cell-lines-xenos-only' => \$cell_lines_xenos_only,
    'cases-only' => \$cases_only,
    'debug' => \$debug,
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
        my $data_type_dir = "$program_download_ctrld_dir/$project_dir/$data_type_dir_name";
        my $dataset_dir_name = $project_name eq 'ALL'
                             ? 'Phase1+2'
                             : '';
        my $dataset_dir = $dataset_dir_name
                        ? "$data_type_dir/$dataset_dir_name"
                        : $data_type_dir;
        my $dataset_cgi_dir = "$dataset_dir/$cgi_dir_name";
        my @cgi_analysis_dirs;
        for my $analysis_dir_name (@cgi_analysis_dir_names) {
            my $cgi_analysis_dir = "$dataset_cgi_dir/$analysis_dir_name";
            push @cgi_analysis_dirs, $cgi_analysis_dir if -d $cgi_analysis_dir;
        }
        if ($debug) {
            print STDERR "\@cgi_analysis_dirs:\n", Dumper(\@cgi_analysis_dirs);
        }
        my @cases = split(/,/, @{$user_params{cases}}) if defined($user_params{cases});
        my $cases_regexp_str = join('|', @cases);
        my $barcode_regexp = $cases_regexp_str
                           ? qr/(([A-Z]+-\d{2}(?:-\d{2})?-(?:$cases_regexp_str))-(\d{2})(?:\.\d+)?[A-Z]-\d{2}[A-Z])/
                           : qr/(([A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+)-(\d{2})(?:\.\d+)?[A-Z]-\d{2}[A-Z])/;
        my %unique_ids;
        find({
            follow => 1,
            wanted => sub {
                if (my ($barcode, $case, $tissue_code) = $_ =~ /$barcode_regexp/) {
                    return if ($no_cell_lines_xenos   and $tissue_code =~ /^(5|6)/) or
                              ($cell_lines_xenos_only and $tissue_code !~ /^(5|6)/);
                    $unique_ids{$case}{$barcode}++;
                }
            },
        },
        @cgi_analysis_dirs);
        if (%unique_ids) {
            for my $case (natsort keys %unique_ids) {
                if ($cases_only) {
                    print "$case\n";
                    next;
                }
                for my $barcode (natsort keys %{$unique_ids{$case}}) {
                    print "$case\t$barcode\n";
                }
            }
        }
    }
}
exit;

__END__

=head1 NAME

find_cgi_cases_barcodes.pl - CGI WGS Case and Barcode Finder

=head1 SYNOPSIS

 find_cgi_cases_barcodes.pl <program name(s)> <project name(s)> <case(s)> [options]
 
 Parameters:
    <program name(s)>           Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>           Comma-separated list of project name(s) (optional, default: all program projects)
    <case(s)>                   Comma-separated list of cases(s) (optional, default: all cases)
 
 Options:
    --no-cell-lines-xenos       Exclude cell lines and xenografts
    --cell-lines-xenos-only     Include only cell lines and xenografts
    --cases-only                Display only cases
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
