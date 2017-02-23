#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw( any none );
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

# config
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
    @cgi_data_dirs);
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
exit;

__END__

=head1 NAME 

find_cgi_cases_barcodes.pl - TARGET CGI Case and Barcode Finder

=head1 SYNOPSIS

 find_cgi_cases_barcodes.pl [options] <proj 1>,<proj 2>,...,<proj n> <case 1>,<case 2>,...,<case n>
 
 Parameters:
    <proj 1>,...,<proj n>       Disease project code(s) (optional: default all disease projects)
    <case 1>,...,<case n>       List of case IDs to search for (optional: default find all barcodes)
 
 Options:
    --no-cell-lines-xenos       Exclude cell lines and xenografts
    --cell-lines-xenos-only     Include only cell lines and xenografts
    --cases-only                Display only cases
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
