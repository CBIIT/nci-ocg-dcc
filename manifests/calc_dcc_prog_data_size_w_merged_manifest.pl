#!/usr/bin/env perl

use strict;
use warnings;
use sigtrap qw(handler sig_handler normal-signals error-signals ALRM);
use Cwd qw(realpath);
use Digest::MD5;
#use Crypt::Digest::SHA256 qw(sha256_file_hex);
use Digest::SHA;
use File::Basename qw(fileparse);
use File::Find;
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(any all none);
use Number::Bytes::Human;
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Term::ANSIColor;
use Data::Dumper;

sub sig_handler {
    die "Caught signal, exiting\n";
}

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# config
my @program_names = qw(
    TARGET
    CGCI
    CTD2
);
my $manifest_delimiter_regexp = qr/(?: (?:\*| )?)/;

my $in_bytes = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'in-bytes' => \$in_bytes,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
pod2usage(
    -message => 'Valid merged manifest file path required',
    -verbose => 0,
) unless @ARGV and -f $ARGV[0];
my $merged_manifest_file = shift @ARGV;
my $program_name = (split('_', fileparse($merged_manifest_file)))[0];
pod2usage(
    -message => 'Invalid merged manifest file name',
    -verbose => 0,
) unless any { $program_name eq $_ } @program_names;
my %checksums;
my $unique_files = 0;
my $total_num_bytes = 0;
my $output_str = '';
my $nbh = Number::Bytes::Human->new();
open(my $fh, '<', $merged_manifest_file) or die "ERROR: $!";
while (<$fh>) {
    next if m/^\s*$/;
    s/\s+$//;
    my ($checksum, $file_rel_path) = split /$manifest_delimiter_regexp/, $_, 2;
    my $file_path = "/local/\L$program_name\E/download/$file_rel_path";
    if (-e $file_path) {
        if (!exists $checksums{$checksum}) {
            $total_num_bytes += -s $file_path;
            $checksums{$checksum}++;
            $unique_files++;
            print "\r", ' ' x length($output_str);
            $output_str = ( $in_bytes ? $total_num_bytes : $nbh->format($total_num_bytes) ) . ", $unique_files unique files";
            print "\r$output_str";
        }
    }
    else {
        print "\nERROR: $file_path doesn't exist\n";
    }
}
close($fh);
print "\n";
exit;

__END__

=head1 NAME 

calc_dcc_prog_data_size_w_merged_manifest.pl - OCG DCC Merged Manifest Program Data Size Calculator

=head1 SYNOPSIS

 calc_dcc_prog_data_size_w_merged_manifest.pl <merged manifest file> [options]
 
 Parameters:
    <merged manifest file>      Merged manifest file path (required)
 
 Options:
    --in-bytes                  Report size(s) in bytes (default off, human-readable sizes)
    --verbose                   Be verbose
    --debug                     Show debug information
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
