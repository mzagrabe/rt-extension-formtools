use warnings;
use strict;

package RT::Extension::FormTools;

our $VERSION = '0.03';

=head2 is_core_field

passed one argument (field name) and checks if
that is a field that we consider 'core' to
RT (subject, AdminCc, etc) rather than something
which should be treated as a Custom Field.

Naming a Custom Field Subject would cause
serious pain with FormTools

=cut

sub is_core_field {
   return $_[0] =~ /^(Requestors|Cc|AdminCc|Subject|UpdateContent|Attach)$/;
}

sub validate_cf {
    my ($CF, $ARGSRef) = @_;
    my $NamePrefix = "Object-RT::Ticket--CustomField-";
    my $field = $NamePrefix . $CF->Id . "-Value";
    my $valid = 1;
    my $value;
    my @res;
    if ($ARGSRef->{"${field}s-Magic"} and exists $ARGSRef->{"${field}s"}) {
        $value = $ARGSRef->{"${field}s"};
        # We only validate Single Combos -- multis can never be user input
        next if ref $value;
    }
    else {
        $value = $ARGSRef->{$field};
    }

    my @values = ();
    if ( ref $value eq 'ARRAY' ) {
        @values = @$value;
    } elsif ( $CF->Type =~ /text/i ) {
        @values = ($value);
    } else {
        @values = split /\r*\n/, ( defined $value ? $value : '');
    }
    @values = grep $_ ne '',
        map {
            s/\r+\n/\n/g;
            s/^\s+//;
            s/\s+$//;
            $_;
        }
        grep defined, @values;
    @values = ('') unless @values;

    foreach my $value( @values ) {
        next if $CF->MatchPattern($value);

        my $msg = "Input must match ". $CF->FriendlyPattern;
        push @res, $msg;
        $valid = 0;
    }
    return ($valid, @res);
}

1;
