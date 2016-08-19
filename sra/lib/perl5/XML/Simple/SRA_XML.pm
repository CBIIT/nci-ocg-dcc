package XML::Simple::SRA_XML;

use base qw(XML::Simple);

sub sorted_keys {
    my ($self, $name, $hashref) = @_;
    # experiment
    if ($name eq 'EXPERIMENT')  {
        my @ordered = qw(
            IDENTIFIERS
            TITLE
            STUDY_REF
            DESIGN
            PLATFORM
            EXPERIMENT_ATTRIBUTES
        );
        my %ordered_hash = map { $_ => 1 } @ordered;
        # set ordered tags in front of others
        return grep { exists $hashref->{$_} } @ordered, grep { !$ordered_hash{$_} } $self->SUPER::sorted_keys($name, $hashref);
    }
    # run
    elsif ($name eq 'RUN') {
        my @ordered = qw(
            alias
            center_name
            run_center
            broker_name
            IDENTIFIERS
            EXPERIMENT_REF
            PLATFORM
            PROCESSING
            DATA_BLOCK
        );
        my %ordered_hash = map { $_ => 1 } @ordered;
        # set ordered tags in front of others
        return grep { exists $hashref->{$_} } @ordered, grep { !$ordered_hash{$_} } $self->SUPER::sorted_keys($name, $hashref);
    }
    # processing
    elsif ($name eq 'PROCESSING') {
        my @ordered = qw(
            PIPELINE
            DIRECTIVES
        );
        my %ordered_hash = map { $_ => 1 } @ordered;
        # set ordered tags in front of others
        return grep { exists $hashref->{$_} } @ordered, grep { !$ordered_hash{$_} } $self->SUPER::sorted_keys($name, $hashref);
    }
    # pipe_section
    elsif ($name eq 'PIPE_SECTION') {
        my @ordered = qw(
            STEP_INDEX
            PREV_STEP_INDEX
            PROGRAM
            VERSION
        );
        my %ordered_hash = map { $_ => 1 } @ordered;
        # set ordered tags in front of others
        return grep { exists $hashref->{$_} } @ordered, grep { !$ordered_hash{$_} } $self->SUPER::sorted_keys($name, $hashref);
    }
    # file
    elsif ($name eq 'FILE') {
        my @ordered = qw(
            checksum
            checksum_method
            filetype
            filename
        );
        my %ordered_hash = map { $_ => 1 } @ordered;
        # set ordered tags in front of others
        return grep { exists $hashref->{$_} } @ordered, grep { !$ordered_hash{$_} } $self->SUPER::sorted_keys($name, $hashref);
    }
    return $self->SUPER::sorted_keys($name, $hashref); # for the rest, I don't care!
}

1;
