#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Config::Tiny;
use Cwd qw( cwd );
use File::Basename qw( basename );
use Getopt::Long qw( :config auto_help auto_version );
use List::MoreUtils qw( firstidx uniq notall none );
use NCI::OCGDCC::Config qw( :all );
use NCI::OCGDCC::Utils qw( get_barcode_info );
use Pod::Usage qw( pod2usage );
use Sort::Key::Natural qw( natsort );
use Text::Template;
use Time::Piece;
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
my %sra_xml_schemas = (
    exp => 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.experiment.xsd?view=co',
    run => 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.run.xsd?view=co',
    sub => 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.submission.xsd?view=co',
);
my $default_manifest_file_name = 'MANIFEST.txt';

my $verbose = 0;
my $debug = 0;
GetOptions(
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my $submission_label = shift(@ARGV) or pod2usage(-message => 'Required parameter: submission label', -verbose => 0);
my $config = Config::Tiny->read("$FindBin::Bin/" . basename($0, '.pl') . '.conf');
die "ERROR: couldn't load config: ", Config::Tiny->errstr unless $config;
print STDERR "\$config:\n", Dumper($config) if $debug;
pod2usage(-message => "No configuration section defined for $submission_label", -verbose => 0) unless exists $config->{$submission_label};
print "[$submission_label]\n";
my %metadata_by_barcode;
# read barcode file
my $barcode_file = "$FindBin::Bin/$submission_label/${submission_label}_barcodes.txt";
print "Loading barcodes $barcode_file\n" if $verbose;
open(my $barcode_fh, '<', $barcode_file) or die "ERROR: could not open $barcode_file: $!";
while (<$barcode_fh>) {
    s/\s+//g;
    next if m/^(?:#|\s*$)/;
    if (!exists $metadata_by_barcode{$_}) {
        @{$metadata_by_barcode{$_}}{qw( tissue_type tissue_name )} = @{get_barcode_info($_)}{qw( tissue_type tissue_name )};
    }
    else {
        die "ERROR: barcode $_ found more than once\n";
    }
}
close($barcode_fh);
print scalar(keys %metadata_by_barcode), " barcodes\n" if $verbose;
# read data file info
print "Reading data file info $config->{$submission_label}->{data_dir}\n" if $verbose;
opendir(my $dh, $config->{$submission_label}->{data_dir}) or die "$!";
my @data_file_names = natsort grep { -f "$config->{$submission_label}->{data_dir}/$_" and $_ ne $default_manifest_file_name } readdir $dh;
closedir($dh);
my $num_data_files_used = 0;
for my $file_name (@data_file_names) {
    if (
        my ($barcode) = $file_name =~ /($OCG_BARCODE_REGEXP)/i
    ) {
        $barcode = uc($barcode);
        if (exists $metadata_by_barcode{$barcode}) {
            my ($file_ext) = $file_name =~ /\.(?:(bam(?:header\.txt)|fastq(?:\.gz)?))$/i;
            my $file_type = lc($file_ext) eq 'bamheader.txt' ? 'bamheader' :
                            lc($file_ext) eq 'fastq.gz'      ? 'fastq'     :
                            lc($file_ext);
            push @{$metadata_by_barcode{$barcode}{'files'}}, {
                name => $file_name,
                type => $file_type,
            };
            if (
                $file_type eq 'bam' or
                $file_type eq 'bamheader'
            ) {
                my @rg_lines;
                if ($file_type eq 'bam') {
                    @rg_lines = grep { s/\s+$//; m/^\@RG/ } `samtools view -H $config->{$submission_label}->{data_dir}/$file_name`
                }
                else {
                    local $/;
                    open(my $bh_fh, '<', "$config->{$submission_label}->{data_dir}/$file_name")
                        or die "ERROR: couldn't open $config->{$submission_label}->{data_dir}/$file_name: $!";
                    @rg_lines = grep { s/\s+$//; m/^\@RG/ } <$bh_fh>;
                    close($bh_fh);
                }
                for (@rg_lines) {
                    my %rg_fields;
                    for (grep { m/:/ } split("\t")) {
                        my ($name, $value) = split(':');
                        $rg_fields{$name} = $value;
                    }
                    push @{$metadata_by_barcode{$barcode}{'readgroup_data'}}, \%rg_fields;
                }
            }
            $num_data_files_used++;
        }
    }
    else {
        die "ERROR: could not obtain barcode from $file_name";
    }
}
print "$num_data_files_used files used\n" if $verbose;
# read manifest file
my $manifest_file = "$config->{$submission_label}->{data_dir}/$default_manifest_file_name";
print "Loading checksums $manifest_file\n" if $verbose;
open(my $checksums_fh, '<', $manifest_file) or die "ERROR: could not open $manifest_file: $!";
my $num_checksums_loaded = 0;
while (<$checksums_fh>) {
    next if m/^\s*$/;
    s/^\s+//;
    s/\s+$//;
    my ($checksum, $file_name) = split / (?:\*| )/, $_, 2;
    if (my ($barcode) = $file_name =~ /($OCG_BARCODE_REGEXP)/i) {
        $barcode = uc($barcode);
        if (exists $metadata_by_barcode{$barcode}) {
            my $file_idx = firstidx { $_->{'name'} eq $file_name } @{$metadata_by_barcode{$barcode}{'files'}};
            if ($file_idx >= 0) {
                if (!exists $metadata_by_barcode{$barcode}{files}[$file_idx]{'checksum'}) {
                    $metadata_by_barcode{$barcode}{'files'}[$file_idx]{'checksum'} = $checksum;
                    $metadata_by_barcode{$barcode}{'files'}[$file_idx]{'checksum_method'} = length($checksum) == 32 ? 'MD5' : 'SHA256';
                    $num_checksums_loaded++;
                }
                else {
                    die "ERROR: $file_name checksum already loaded\n";
                }
            }
            else {
                die "ERROR: $file_name not loaded when reading data files\n";
            }
        }
    }
    else {
        die "ERROR: could not obtain barcode from $file_name\n";
    }
}
close($checksums_fh);
print "$num_checksums_loaded checksums loaded\n" if $verbose;
# read metadata file
my $metadata_file = "$FindBin::Bin/$submission_label/${submission_label}_metadata.txt";
print "Loading metadata $metadata_file\n" if $verbose;
open(my $metadata_fh, '<', $metadata_file) or die "ERROR: could not open $metadata_file: $!";
my (%meta_file_by_readgroup, %meta_file_col_idx_by_name);
my $num_metadata_rows_loaded = 0;
while (<$metadata_fh>) {
    next if m/^\s*$/;
    s/^\s+//;
    s/\s+$//;
    if (!%meta_file_col_idx_by_name) {
        my @col_headers = split /\t/;
        for (@col_headers) {
            s/^\s+//;
            s/\s+$//;
        }
        %meta_file_col_idx_by_name = map { $col_headers[$_] => $_ } 0 .. $#col_headers;
        for my $col_name ('barcode') {
            die "ERROR: missing '$col_name' column in $metadata_file\n" unless exists $meta_file_col_idx_by_name{$col_name};
        }
    }
    elsif (%meta_file_col_idx_by_name) {
        my @fields = split /\t/;
        for (@fields) {
            s/^\s+//;
            s/\s+$//;
        }
        my $readgroup = $fields[$meta_file_col_idx_by_name{'readgroup'}];
        if (!exists $meta_file_by_readgroup{$readgroup}) {
            for my $col_name (grep { $_ ne 'readgroup' } keys %meta_file_col_idx_by_name) {
                $meta_file_by_readgroup{$readgroup}{$col_name} = $fields[$meta_file_col_idx_by_name{$col_name}];
            }
        }
        else {
            die "ERROR: $readgroup readgroup specified twice\n";
        }
        $num_metadata_rows_loaded++;
    }
}
close($metadata_fh);
print "$num_metadata_rows_loaded metadata rows loaded\n" if $verbose;
my %add_metadata_by_library_id;
if ($submission_label =~ /^target_os_w(g|x)s_nci-meltzer/) {
    open(my $s_fh, '<', "$FindBin::Bin/$submission_label/sequencers.csv")
        or die "ERROR: could not open sequencers.csv: $!";
    <$s_fh>;
    my %s_model_by_name;
    while (<$s_fh>) {
        s/\s+$//;
        my ($name, $model) = split(',');
        $s_model_by_name{$name} = $model;
    }
    close($s_fh);
    open(my $in_fh, '<', "$FindBin::Bin/$submission_label/sequence_metadata.csv")
        or die "ERROR: could not open sequence_metadata.csv: $!";
    <$in_fh>;
    while (<$in_fh>) {
        s/\s+$//;
        my @fields = split(',');
        # skip non-WXS rows
        #next unless $fields[2] and $fields[2] ne 'None';
        $fields[2] =~ s/_/ /g;
        $fields[2] =~ s/\s+kit$//i;
        $fields[2] .= ' Custom Capture' if $fields[2] =~ /MECOM$/;
        if (!defined $add_metadata_by_library_id{$fields[1]}) {
            $add_metadata_by_library_id{$fields[1]} = {
                sequencer_models => [ $s_model_by_name{$fields[3]} ],
                run_dates => [ $fields[4] ],
            };
            $add_metadata_by_library_id{$fields[1]}{capture_kit} = $fields[2] if $fields[2];
        }
        else {
            if (none { $fields[4] eq $_ } @{$add_metadata_by_library_id{$fields[1]}{run_dates}}) {
                push @{$add_metadata_by_library_id{$fields[1]}{run_dates}}, $fields[4];
            }
            if (none { $s_model_by_name{$fields[3]} eq $_ } @{$add_metadata_by_library_id{$fields[1]}{sequencer_models}}) {
                push @{$add_metadata_by_library_id{$fields[1]}{sequencer_models}}, $s_model_by_name{$fields[3]};
            }
        }
    }
    close($in_fh);
    print STDERR "\%add_metadata_by_library_id:\n", Dumper(\%add_metadata_by_library_id) if $debug;
}
my $is_missing_metadata;
for my $barcode (natsort keys %metadata_by_barcode) {
    for my $rg_hashref (@{$metadata_by_barcode{$barcode}{'readgroup_data'}}) {
        if (exists $meta_file_by_readgroup{$rg_hashref->{'ID'}}) {
            for my $col_name (keys %{$meta_file_by_readgroup{$rg_hashref->{'ID'}}}) {
                if ($col_name eq 's_case_id') {
                    if ($meta_file_by_readgroup{$rg_hashref->{'ID'}}{$col_name} ne get_barcode_info($barcode)->{'s_case_id'}) {
                        die "ERROR: metadata file s_case_id '$meta_file_by_readgroup{$rg_hashref->{'ID'}}{$col_name}' doesn't match $barcode\n";
                    }
                    if (!exists $metadata_by_barcode{$barcode}{'case_id'}) {
                        $metadata_by_barcode{$barcode}{'case_id'} = get_barcode_info($barcode)->{'case_id'};
                    }
                }
                elsif ($col_name eq 'software' or 
                       $col_name eq 'software_version') {
                    if (!exists $metadata_by_barcode{$barcode}{$col_name}) {
                        $metadata_by_barcode{$barcode}{$col_name} = $meta_file_by_readgroup{$rg_hashref->{'ID'}}{$col_name};
                    }
                    #elsif ($metadata_by_barcode{$barcode}{$col_name} ne $meta_file_by_readgroup{$rg_hashref->{'ID'}}{$col_name}) {
                    #    die "ERROR: metadata file $barcode $col_name inconsistencies\n";
                    #}
                }
                elsif (!exists $rg_hashref->{$col_name}) {
                    $rg_hashref->{$col_name} = $meta_file_by_readgroup{$rg_hashref->{'ID'}}{$col_name};
                }
                else {
                    die "ERROR: $col_name readgroup data already exists\n";
                }
            }
            #if (exists $meta_file_by_readgroup{$rg_hashref->{'ID'}}{'barcode'} and
            #    $meta_file_by_readgroup{$rg_hashref->{'ID'}}{'barcode'} ne $barcode) {
            #    print "ERROR: metadata file '$meta_file_by_readgroup{$rg_hashref->{'ID'}}{'barcode'}' doesn't match $barcode\n";
            #}
        }
        else {
            print "ERROR: $barcode $rg_hashref->{'ID'} missing metadata\n";
            $is_missing_metadata++;
        }
        if (%add_metadata_by_library_id) {
            if ($submission_label =~ /^target_os_wxs_nci-meltzer/) {
                if (none { $add_metadata_by_library_id{$rg_hashref->{'LB'}}{capture_kit} eq $_ } @{$metadata_by_barcode{$barcode}{capture_kits}}) {
                    push @{$metadata_by_barcode{$barcode}{capture_kits}}, $add_metadata_by_library_id{$rg_hashref->{'LB'}}{capture_kit};
                }
            }
            for my $run_date (@{$add_metadata_by_library_id{$rg_hashref->{'LB'}}{run_dates}}) {
                if (none { $run_date eq $_ } @{$metadata_by_barcode{$barcode}{run_dates}}) {
                    push @{$metadata_by_barcode{$barcode}{run_dates}}, $run_date;
                }
            }
            for my $sequencer_model (@{$add_metadata_by_library_id{$rg_hashref->{'LB'}}{sequencer_models}}) {
                if (none { $sequencer_model eq $_ } @{$metadata_by_barcode{$barcode}{sequencer_models}}) {
                    push @{$metadata_by_barcode{$barcode}{sequencer_models}}, $sequencer_model;
                }
            }
        }
    }
    if (notall { $_ eq $barcode } map { $_->{'barcode'} } @{$metadata_by_barcode{$barcode}{'readgroup_data'}}) {
        print "ERROR: barcode issues: $barcode\t", join("\t", reverse natsort uniq(map { $_->{'barcode'} } @{$metadata_by_barcode{$barcode}{'readgroup_data'}})), "\n";
    }
    if (%add_metadata_by_library_id) {
        my ($title, $design_description, $library_construction_protocol);
        if ($submission_label =~ /^target_os_wxs_nci-meltzer/) {
            $title = "TARGET Osteosarcoma Subject $metadata_by_barcode{$barcode}{case_id} $metadata_by_barcode{$barcode}{tissue_type} $metadata_by_barcode{$barcode}{tissue_name} Whole Exome Sequence";
            my $capture_kits_str = join(' and ', sort @{$metadata_by_barcode{$barcode}{capture_kits}}) . ' ' . ( scalar(@{$metadata_by_barcode{$barcode}{capture_kits}} > 1) ? 'kits' : 'kit' );
            delete $metadata_by_barcode{$barcode}{capture_kits};
            $library_construction_protocol = <<"            LIB_CONST_PROT";
            Genomic DNA was isolated using the Qiagen AllPrep Kit.
            Conventional Illumina DNA sequencing libraries for whole exome sequencing were prepared using 1 mcg genomic DNA fragmented to a mean size of approximately 350 bp in an S1 Covaris Sonicator.
            Exome sequence was captured for Illumina sequencing following the manufacturers' instructions using the $capture_kits_str.
            LIB_CONST_PROT
            $design_description = <<"            DESIGN_DESC";
            Whole exome sequence analysis of $barcode using $capture_kits_str.
            DESIGN_DESC
        }
        elsif ($submission_label =~ /^target_os_wgs_nci-meltzer/) {
            $title = "TARGET Osteosarcoma Subject $metadata_by_barcode{$barcode}{case_id} $metadata_by_barcode{$barcode}{tissue_type} $metadata_by_barcode{$barcode}{tissue_name} Whole Genome Sequence";
            $library_construction_protocol = <<"            LIB_CONST_PROT";
            Genomic DNA was isolated using the Qiagen AllPrep Kit.
            Whole genome sequencing libraries were prepared using either Illumina's Genomic DNA Sample Prep starting with 1 mcg genomic DNA or the Illumina Nextera DNA Library Prep Kit according to the manufacturer's protocol.
            LIB_CONST_PROT
            $design_description = <<"            DESIGN_DESC";
            Whole genome sequence analysis of $barcode.
            DESIGN_DESC
        }
        $metadata_by_barcode{$barcode}{title} = $title;
        $library_construction_protocol =~ s/^\s+//;
        $library_construction_protocol =~ s/\s+$//;
        $library_construction_protocol =~ s/\s+/ /g;
        $design_description =~ s/^\s+//;
        $design_description =~ s/\s+$//;
        $design_description =~ s/\s+/ /g;
        $metadata_by_barcode{$barcode}{library_construction_protocol} = $library_construction_protocol;
        if (scalar(@{$metadata_by_barcode{$barcode}{sequencer_models}}) > 1) {
            (my $sequencer_model) = grep { $_ =~ /Genome Analyzer/ } @{$metadata_by_barcode{$barcode}{sequencer_models}};
            if (!defined $sequencer_model) {
                ($sequencer_model) = grep { $_ =~ /HiSeq/ } @{$metadata_by_barcode{$barcode}{sequencer_models}}
            }
            if (defined $sequencer_model) {
                $metadata_by_barcode{$barcode}{sequencer_model} = $sequencer_model;
            }
            else {
                die "ERROR: don't know which sequencer model to use: ", join(',', @{$metadata_by_barcode{$barcode}{sequencer_models}}), "\n";
            }
        }
        else {
            $metadata_by_barcode{$barcode}{sequencer_model} = $metadata_by_barcode{$barcode}{sequencer_models}[0];
        }
        delete $metadata_by_barcode{$barcode}{sequencer_models};
        $metadata_by_barcode{$barcode}{design_description} = $design_description;
        $metadata_by_barcode{$barcode}{run_dates} = join(',', 
            sort {
                Time::Piece->strptime($a, '%Y-%m-%d') <=> Time::Piece->strptime($b, '%Y-%m-%d')
            } @{$metadata_by_barcode{$barcode}{run_dates}}
        );
    }
}
exit(1) if $is_missing_metadata;
print STDERR "\%metadata_by_barcode:\n", Dumper(\%metadata_by_barcode) if $debug;
# generate XML files from templates
my $exp_xml_file = "$FindBin::Bin/$submission_label/${submission_label}.exp.xml";
my $run_xml_file = "$FindBin::Bin/$submission_label/${submission_label}.run.xml";
print "Building SRA-XML\n",
      "Generating $exp_xml_file\n",
      "Generating $run_xml_file\n";
open(my $exp_xml_fh, '>', $exp_xml_file) or die "ERROR: could not create $exp_xml_file: $!";
open(my $run_xml_fh, '>', $run_xml_file) or die "ERROR: could not create $run_xml_file: $!";
print $exp_xml_fh <<'EXP_XML';
<EXPERIMENT_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                xsi:noNamespaceSchemaLocation="http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.experiment.xsd?view=co">
EXP_XML
print $run_xml_fh <<'RUN_XML';
<RUN_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
         xsi:noNamespaceSchemaLocation="http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.run.xsd?view=co">
RUN_XML
my $exp_xml_tmpl = Text::Template->new(
    TYPE => 'FILE',
    SOURCE => -f "$FindBin::Bin/$submission_label/${submission_label}.exp.xml.tmpl" 
        ? "$FindBin::Bin/$submission_label/${submission_label}.exp.xml.tmpl" 
        : "$FindBin::Bin/default.exp.xml.tmpl",
) or die "ERROR: couldn't construct template ${submission_label}.exp.xml.tmpl: $Text::Template::ERROR";
my $run_xml_tmpl = Text::Template->new(
    TYPE => 'FILE',
    SOURCE => -f "$FindBin::Bin/$submission_label/${submission_label}.run.xml.tmpl" 
        ? "$FindBin::Bin/$submission_label/${submission_label}.run.xml.tmpl" 
        : "$FindBin::Bin/default.run.xml.tmpl",
) or die "ERROR: couldn't construct template ${submission_label}.run.xml.tmpl: $Text::Template::ERROR";
for my $barcode (natsort keys %metadata_by_barcode) {
    my %metadata_hash = map { 
        $_ => $metadata_by_barcode{$barcode}{$_} 
    } 
    grep {
        $_ ne 'files' and
        $_ ne 'readgroup_data'
    }
    keys %{$metadata_by_barcode{$barcode}};
    if (!exists $metadata_hash{'library_name'}) {
        $metadata_hash{'library_name'} = join(',', natsort uniq(map { $_->{'LB'} } @{$metadata_by_barcode{$barcode}{'readgroup_data'}}));
    }
    my %files_hash = map {
        ( "file_name_" . ( $_ + 1 )    ) => $metadata_by_barcode{$barcode}{files}[$_]{'name'},
        ( "file_checksum_" . ( $_ + 1 ) ) => $metadata_by_barcode{$barcode}{files}[$_]{'checksum'},
        ( "file_checksum_method_" . ( $_ + 1 ) ) => $metadata_by_barcode{$barcode}{files}[$_]{'checksum_method'},
    } 0 .. $#{$metadata_by_barcode{$barcode}{'files'}};
    if ($debug) {
        print STDERR "$barcode tt hash:\n", Dumper({
            broker_name => $config->{_}->{broker_name},
            center_name => $config->{$submission_label}->{center_name},
            barcode => $barcode,
            assembly => $config->{$submission_label}->{assembly},
            %metadata_hash,
            %files_hash,
        });
    }
    $exp_xml_tmpl->fill_in(
        OUTPUT => $exp_xml_fh,
        HASH => {
            broker_name => $config->{_}->{broker_name},
            center_name => $config->{$submission_label}->{center_name},
            barcode => $barcode,
            assembly => $config->{$submission_label}->{assembly},
            %metadata_hash,
        },
    ) or die "ERROR: couldn't fill in template ${submission_label}.exp.xml.tmpl: $Text::Template::ERROR";
    $run_xml_tmpl->fill_in(
        OUTPUT => $run_xml_fh,
        HASH => {
            broker_name => $config->{_}->{broker_name},
            center_name => $config->{$submission_label}->{center_name},
            barcode => $barcode,
            assembly => $config->{$submission_label}->{assembly},
            %metadata_hash,
            %files_hash,
        },
    ) or die "ERROR: couldn't fill in template ${submission_label}.run.xml.tmpl: $Text::Template::ERROR";
}
print $exp_xml_fh '</EXPERIMENT_SET>', "\n";
print $run_xml_fh '</RUN_SET>', "\n";
close($exp_xml_fh);
close($run_xml_fh);
my $sub_xml_file = "$FindBin::Bin/$submission_label/${submission_label}.sub.xml";
print "Generating $sub_xml_file\n";
open(my $sub_xml_fh, '>', $sub_xml_file) or die "ERROR: could not create $sub_xml_file: $!";
my $sub_xml_tmpl = Text::Template->new(
    TYPE => 'FILE',
    SOURCE => -f "$FindBin::Bin/$submission_label/${submission_label}.sub.xml.tmpl"
        ? "$FindBin::Bin/$submission_label/${submission_label}.sub.xml.tmpl" 
        : "$FindBin::Bin/default.sub.xml.tmpl",
) or die "ERROR: couldn't construct template ${submission_label}.sub.xml.tmpl: $Text::Template::ERROR";
$sub_xml_tmpl->fill_in(
    OUTPUT => $sub_xml_fh,
    HASH => {
        broker_name => $config->{_}->{broker_name},
        center_name => $config->{$submission_label}->{center_name},
        submission_label => $submission_label,
        submission_name => uc($submission_label),
    },
) or die "ERROR: couldn't fill in template ${submission_label}.sub.xml.tmpl: $Text::Template::ERROR";
close($sub_xml_fh);
print "Validating SRA-XML\n";
for my $xml_type (sort keys %sra_xml_schemas) {
    my $xml_file = 
        "$FindBin::Bin/$submission_label/${submission_label}_${xml_type}.xml";
    if (-f $xml_file) {
        my $xmllint_cmd = "xmllint --noout --schema $sra_xml_schemas{$xml_type} $xml_file";
        print "$xmllint_cmd\n" if $verbose;
        system(split(' ', $xmllint_cmd)) == 0 or warn "ERROR: xmllint failed: ", $? >> 8, "\n";
    }
}
exit;

__END__

=head1 NAME 

generate_sra_xml_submission.pl - SRA-XML Submission Generator

=head1 SYNOPSIS

 generate_sra_xml_submission.pl <submission label> [options]
 
 Parameters:
    <submission label>          Submission label used in config file and directory
 
 Options:
    --verbose                   Be verbose
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
