#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Basename qw(fileparse);
use File::Copy qw(copy);
use File::Find;
use File::Path 2.11 qw(make_path remove_tree);
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(any);
use Pod::Usage qw(pod2usage);
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $CGI_CASE_DIR_REGEXP = qr/${CASE_REGEXP}(?:(?:-|_)\d+)?/;

# config
my @target_cgi_proj_codes = qw(
    ALL
    AML
    CCSK
    NBL
    OS
    WT
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
pod2usage(-message => 'Project code required',
          -verbose => 0) unless @ARGV;
my $project_code = shift @ARGV;
pod2usage(-message => "Invalid project code should be one of: " . join(',', @target_cgi_proj_codes),
          -verbose => 0) unless any { $project_code eq $_ } @target_cgi_proj_codes;
my %cog_ids;
if (!$clean_only) {
    pod2usage(-message => 'Comma-separated list of COG IDs or COG ID file required',
              -verbose => 0) unless @ARGV;
    my $cog_param_str = shift @ARGV;
    if ($cog_param_str =~ /,/) {
        %cog_ids = map { s/\s+//g; $_ => 1 } split(',', $cog_param_str);
    }
    else {
        if (-f $cog_param_str) {
            open(my $in_fh, '<', $cog_param_str) or die "$!";
            while (<$in_fh>) {
                s/\s+//g;
                $cog_ids{$_}++;
            }
            close($in_fh);
        }
        else {
            pod2usage(-message => "Invalid file: $cog_param_str",
                      -verbose => 0);
        }
    }
    if ($debug) {
        print STDERR Dumper(\%cog_ids), "\n";
    }
}
my ($project, $subproject) = split('-', $project_code);
my $wgs_dataset_dir = "/local/target/data/$project/WGS/current";
die "ERROR: invalid WGS dataset directory $wgs_dataset_dir\n" unless -d $wgs_dataset_dir;
print "Using $wgs_dataset_dir\n";
(my $wgs_ctrld_download_dir = $wgs_dataset_dir) =~ s/data/download\/Controlled/;
$wgs_ctrld_download_dir =~ s/\/current//;
(my $wgs_public_download_dir = $wgs_dataset_dir) =~ s/data/download\/Public/;
$wgs_public_download_dir =~ s/\/current//;
print "Cleaning dataset download dirs\n";
for my $download_dir ($wgs_ctrld_download_dir, $wgs_public_download_dir) {
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
            if (my ($case_id) = $dir =~ /(?:Pilot|Option)AnalysisPipeline2\/($CASE_REGEXP)/) {
                if ($cog_ids{(split('-', $case_id))[2]}) {
                    if (-l $dir) {
                        (my $download_parent_dir = $parent_dir) =~ s/data/download\/Controlled/;
                        $download_parent_dir =~ s/\/current//;
                        if (!-e $download_parent_dir and !$dry_run) {
                            print "Creating $download_parent_dir\n";
                            make_path($download_parent_dir, {
                                chmod => 0750,
                                owner => 'ocg-dcc-adm',
                                group => 'target-dn-ctrld',
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
                            owner => 'ocg-dcc-adm',
                            group => $is_ctrld ? 'target-dn-ctrld' : 'target-dn-adm',
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
            if (my ($case_id) = $file_name =~ /($CASE_REGEXP)/) {
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
                            owner => 'ocg-dcc-adm',
                            group => $is_ctrld ? 'target-dn-ctrld' : 'target-dn-adm',
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
                        owner => 'ocg-dcc-adm',
                        group => 'target-dn-adm',
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
$wgs_dataset_dir);
my $rmdir_ctrld_cmd_str       = "find $wgs_ctrld_download_dir -depth -type d -empty -exec rmdir -v {} \\;";
my $rmdir_public_cmd_str      = "find $wgs_public_download_dir -depth -type d -empty -exec rmdir -v {} \\;";
my $dir_chmod_ctrld_cmd_str   = "find $wgs_ctrld_download_dir -type d -exec chmod 0550 {} \\;";
my $dir_chmod_public_cmd_str  = "find $wgs_public_download_dir -type d -exec chmod 0555 {} \\;";
my $file_chmod_ctrld_cmd_str  = "find $wgs_ctrld_download_dir -type f -exec chmod 0440 {} \\;";
my $file_chmod_public_cmd_str = "find $wgs_public_download_dir -type f -exec chmod 0444 {} \\;";
my $chown_ctrld_cmd_str       = "chown -R ocg-dcc-adm:target-dn-ctrld $wgs_ctrld_download_dir";
my $chown_public_cmd_str      = "chown -R ocg-dcc-adm:target-dn-adm $wgs_public_download_dir";
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
exit;

__END__

=head1 NAME 

generate_target_cgi_data_subset.pl - TARGET CGI Data Subset Generator

=head1 SYNOPSIS

 generate_target_cgi_data_subset.pl [options] <proj> <cog1>,<cog2>,... | <cog file>
 
 Parameters:
    <proj>                              Disease project code
    <cog1>,<cog2>,... | <cog file>      Comma-separated list of COG IDs or txt file with list of COG IDs
 
 Options:
    --verbose                           Be verbose
    --dry-run                           Show what would be done
    --clean-only                        Clean up existing dataset in public/controlled access areas and exit
    --debug                             Show debug information
    --help                              Display usage message and exit
    --version                           Display program version and exit

=cut
