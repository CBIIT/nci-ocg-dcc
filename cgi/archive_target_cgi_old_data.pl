#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Basename qw(fileparse);
use File::Copy qw(move);
use File::Copy::Recursive qw(dirmove);
use File::Find;
use File::Path 2.11 qw(make_path);
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw(any);
use Pod::Usage qw(pod2usage);
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

# config
my @target_cgi_proj_codes = qw(
    ALL
    AML
    CCSK
    NBL
    OS
    WT
);
my $target_data_dir = '/local/target/data';
my $cgi_dir_name = 'CGI';
my @cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);
my @cgi_manifest_file_names = qw(
    manifest.all.unencrypted
    manifest.dcc.unencrypted
);
my $dir_mode = 0770;
my $file_mode = 0660;
my $owner = 'ocg-dcc-adm';
my $group = 'ocg-dcc-adm';
my $uid = getpwnam($owner);
my $gid = getgrnam($group);

my $verbose = 0;
my $dry_run = 0;
my $debug = 0;
GetOptions(
    'verbose' => \$verbose,
    'dry-run' => \$dry_run,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if ($< != 0 and !$dry_run) {
    pod2usage(
        -message => 'Script must be run with sudo',
        -verbose => 0,
    );
}
my %user_cgi_proj_codes;
if (@ARGV) {
    %user_cgi_proj_codes = map { uc($_) => 1 } split(',', shift @ARGV);
    print STDERR "\%user_cgi_proj_codes:\n", Dumper(\%user_cgi_proj_codes) if $debug;
}
for my $proj_code (@target_cgi_proj_codes) {
    next if %user_cgi_proj_codes and !$user_cgi_proj_codes{uc($proj_code)};
    print "[$proj_code]\n";
    my ($project, $subproject) = split('-', $proj_code);
    my $cgi_dataset_dir = "$target_data_dir/$project";
    $cgi_dataset_dir .= '/Phase_II' if $project =~ /ALL/;
    $cgi_dataset_dir .= ( defined $subproject ? '/Model_Systems' : '/Discovery' ) .
                        "/WGS/current/$cgi_dir_name";
    if ($debug) {
        print STDERR "\$cgi_dataset_dir:\n$cgi_dataset_dir\n";
    }
    my @cgi_data_dirs;
    #for my $dir_name (@cgi_data_dir_names) {
    #    my $cgi_data_dir = "$cgi_dataset_dir/$dir_name";
    #    push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
    #}
    push @cgi_data_dirs, $cgi_dataset_dir;
    if ($debug) {
        print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs);
    }
    find({
        follow => 1,
        wanted => sub {
            my $parent_dir_path = $File::Find::dir;
            (my $archive_dir_path = $parent_dir_path) =~ s/WGS\/current\/$cgi_dir_name/WGS\/old\/$cgi_dir_name/
                or die "\nERROR: invalid directory path $parent_dir_path\n\n";
            # directories
            if (-d) {
                my $dir_name = $_;
                my $dir_path = $File::Find::name;
                # old_data, corrupted directories
                if ($dir_name eq 'old_data' or
                    $dir_name eq 'corrupted') {
                    # corrupted directories will be archived retaining the directory
                    if ($dir_name eq 'corrupted') {
                        $archive_dir_path .= "/$dir_name";
                    }
                    if (!-z $dir_path) {
                        if (!-e $archive_dir_path) {
                            print "Creating $archive_dir_path\n" if $verbose;
                            if (!$dry_run) {
                                make_path($archive_dir_path, {
                                    chmod => $dir_mode,
                                    owner => $owner,
                                    group => $group,
                                }) or warn "ERROR: could not create $archive_dir_path\n";
                            }
                        }
                        print "  Moving $dir_path ->\n",
                              "         $archive_dir_path\n" if $verbose;
                        if (!$dry_run) {
                            dirmove($dir_path, $archive_dir_path) or
                                warn "ERROR: could not move directory: $!\n",
                                     "$dir_path ->\n$archive_dir_path\n";
                            $File::Find::prune = 1;
                        }
                    }
                    else {
                        print "Removing $dir_path\n" if $verbose;
                        if (!$dry_run) {
                            rmdir($dir_path)
                                or warn "ERROR: could not remove empty $dir_path: $!\n";
                            $File::Find::prune = 1;
                        }
                    }
                }
            }
            # files
            elsif (-f) {
                my $file_name = $_;
                my $file_path = $File::Find::name;
                # old manifest and bak files
                if ($file_name =~ /(?:^manifest\.all(?:(?:.*?\.(?:old|orig))?|\.sig)|\.bak)$/i) {
                    my ($file_basename, $file_dir, $file_ext) = fileparse($file_path, qr/\..*/);
                    $file_dir =~ s/\/$//;
                    my @dir_parts = File::Spec->splitdir($file_dir);
                    # special case for Analysis directory files
                    if ($dir_parts[$#dir_parts] eq 'Analysis') {
                        my @file_basename_parts = split('_', $file_basename);
                        my $file_date_part = join('_', @file_basename_parts[$#file_basename_parts - 2 .. $#file_basename_parts]);
                        $archive_dir_path .= "/$file_date_part";
                    }
                    # special case for bak files
                    if ($file_name =~ /\.bak$/i) {
                        $file_name =~ s/\.bak$//i;
                    }
                    if (!-e $archive_dir_path) {
                        print "Creating $archive_dir_path\n" if $verbose;
                        if (!$dry_run) {
                            make_path($archive_dir_path, {
                                chmod => $dir_mode,
                                owner => $owner,
                                group => $group,
                            }) or warn "ERROR: could not create $archive_dir_path\n";
                        }
                    }
                    # backup archive if exists
                    my $backup_success;
                    if (-e "$archive_dir_path/$file_name") {
                        for (my $i = 1; ; $i++) {
                            if (!-e "$archive_dir_path/${file_name}.$i") {
                                print "  Moving $archive_dir_path/$file_name ->\n",
                                      "         $archive_dir_path/${file_name}.$i\n" if $verbose;
                                if (!$dry_run) {
                                    if (move("$archive_dir_path/$file_name", "$archive_dir_path/${file_name}.$i")) {
                                        $backup_success++;
                                    }
                                    else {
                                        warn "ERROR: could not move file: $!\n",
                                             "$archive_dir_path/$file_name ->\n$archive_dir_path/${file_name}.$i\n";
                                    }
                                }
                                last;
                            }
                        }
                    }
                    else {
                        $backup_success++;
                    }
                    # archive file
                    if ($backup_success or $dry_run) {
                        print "  Moving $file_path ->\n",
                              "         $archive_dir_path/$file_name\n" if $verbose;
                        if (!$dry_run) {
                            if (move($file_path, "$archive_dir_path/$file_name")) {
                                chmod($file_mode, "$archive_dir_path/$file_name");
                                chown($uid, $gid, "$archive_dir_path/$file_name");
                            }
                            else {
                                warn "ERROR: could not move file: $!\n",
                                     "$file_path ->\n$archive_dir_path/$file_name\n";
                            }
                        }
                    }
                }
                # current manifest files
                elsif (any { $file_name eq $_ } @cgi_manifest_file_names) {
                    open(my $manifest_in_fh, '<', $file_path)
                            or die "\nERROR: could not open for read $file_path\n\n";
                    my @manifest_file_old_data_lines;
                    while (<$manifest_in_fh>) {
                        next if m/^\s*$/;
                        my ($checksum, $rel_file_path) = split(' ', $_, 2);
                        if ($rel_file_path =~ /\/old_data\//) {
                            push @manifest_file_old_data_lines, $_;
                        }
                    }
                    close($manifest_in_fh);
                    if (@manifest_file_old_data_lines) {
                        if (!-e $archive_dir_path) {
                            print "Creating $archive_dir_path\n" if $verbose;
                            if (!$dry_run) {
                                make_path($archive_dir_path, {
                                    chmod => $dir_mode,
                                    owner => $owner,
                                    group => $group,
                                }) or warn "ERROR: could not create $archive_dir_path\n";
                            }
                        }
                        # filter out old_data path entries
                        open(my $manifest_in_fh, '<', $file_path)
                            or die "\nERROR: could not open for read $file_path\n\n";
                        my @new_manifest_file_lines;
                        while (<$manifest_in_fh>) {
                            next if m/^\s*$/;
                            my ($checksum, $rel_file_path) = split(' ', $_, 2);
                            if ($rel_file_path !~ /\/old_data\//) {
                                push @new_manifest_file_lines, $_;
                            }
                        }
                        close($manifest_in_fh);
                        # backup archive if exists
                        my $backup_success;
                        if (-e "$archive_dir_path/$file_name") {
                            for (my $i = 1; ; $i++) {
                                if (!-e "$archive_dir_path/${file_name}.$i") {
                                    print "  Moving $archive_dir_path/$file_name ->\n",
                                          "         $archive_dir_path/${file_name}.$i\n" if $verbose;
                                    if (!$dry_run) {
                                        if (!$dry_run) {
                                            if (move("$archive_dir_path/$file_name", "$archive_dir_path/${file_name}.$i")) {
                                                $backup_success++;
                                            }
                                            else {
                                                warn "ERROR: could not move file: $!\n",
                                                     "$archive_dir_path/$file_name ->\n$archive_dir_path/${file_name}.$i\n";
                                            }
                                        }
                                    }
                                    last;
                                }
                            }
                        }
                        else {
                            $backup_success++;
                        }
                        # archive file
                        my $archive_success;
                        if ($backup_success or $dry_run) {
                            print "  Moving $file_path ->\n",
                                  "         $archive_dir_path/$file_name\n" if $verbose;
                            if (!$dry_run) {
                                if (move($file_path, "$archive_dir_path/$file_name")) {
                                    $archive_success++;
                                    chmod($file_mode, "$archive_dir_path/$file_name");
                                    chown($uid, $gid, "$archive_dir_path/$file_name");
                                }
                                else {
                                    warn "ERROR: could not move file $!\n",
                                         "$file_path ->\n$archive_dir_path/$file_name\n";
                                }
                            }
                        }
                        # create new manifest file
                        if ($archive_success or $dry_run) {
                            print "Creating $file_path\n" if $verbose;
                            if (!$dry_run) {
                                open(my $manifest_out_fh, '>', $file_path)
                                    or die "\nERROR: could not open for write $file_path\n\n";
                                print $manifest_out_fh @new_manifest_file_lines;
                                close($manifest_out_fh);
                                chmod($file_mode, "$archive_dir_path/$file_name");
                                chown($uid, $gid, "$archive_dir_path/$file_name");
                            }
                        }
                    }
                }
            }
        },
    },
    @cgi_data_dirs);
}
exit;

__END__

=head1 NAME 

archive_target_cgi_old_data.pl - TARGET CGI Old Data and Manifest Archiver

=head1 SYNOPSIS

 sudo archive_target_cgi_old_data.pl [options] <proj 1>,<proj 2>,...,<proj n>
 
 Parameters:
    <proj 1>,<proj 2>,...,<proj n>      Disease project code(s) (optional: default all disease projects)
 
 Options:
    --verbose                           Be verbose
    --dry-run                           Show what would be done
    --debug                             Show debug information
    --help                              Display usage message and exit
    --version                           Display program version and exit

=cut

