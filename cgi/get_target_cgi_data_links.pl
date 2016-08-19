#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd qw(realpath);
use File::Find;
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
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
my @target_cgi_project_names = qw(
    ALL
    AML
    CCSK
    NBL
    OS
    WT
);
my $target_download_dir = '/local/target/download';
my $cgi_dir_name = 'CGI';
my @target_cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);

my $new_ctrld_rel = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'new-ctrld-rel' => \$new_ctrld_rel,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
for my $project_name (@target_cgi_project_names) {
    my $cgi_dataset_dir = "$target_download_dir/$project_name/WGS/$cgi_dir_name";
    my @cgi_data_dirs;
    for my $data_dir_name (@target_cgi_data_dir_names) {
        my $cgi_data_dir = "$cgi_dataset_dir/$data_dir_name";
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
            if ($new_ctrld_rel) {
                $link =~ s/^\/local\/target\/download/\/local\/target\/download\/Controlled/;
                $link_dir =~ s/^\/local\/target\/download/\/local\/target\/download\/Controlled/;
                $target =~ s/^\/local/\/local\/target\/download\/Controlled\/CGI/;
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
