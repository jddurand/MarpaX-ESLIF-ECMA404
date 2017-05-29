use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::ValueInterface;

# ABSTRACT: MarpaX::ESLIF::ECMA404 Value Interface

# VERSION

# AUTHORITY

=head1 DESCRIPTION

MarpaX::ESLIF::ECMA404's Value Interface

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404::ValueInterface;

    my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new();

=cut

# -----------
# Constructor
# -----------

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new value interface object.

=cut

sub new                { bless [], $_[0] }

# ----------------
# Required methods
# ----------------

=head2 Required methods

=head3 isWithHighRankOnly

Returns a true or a false value, indicating if valuation should use highest ranked rules or not, respectively. Default is a true value.

=cut

sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?

=head3 isWithOrderByRank

Returns a true or a false value, indicating if valuation should order by rule rank or not, respectively. Default is a true value.

=cut

sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?

=head3 isWithAmbiguous

Returns a true or a false value, indicating if valuation should allow ambiguous parse tree or not, respectively. Default is a false value.

=cut

sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?

=head3 isWithNull

Returns a true or a false value, indicating if valuation should allow a null parse tree or not, respectively. Default is a false value.

=cut

sub isWithNull         { 0 }  # Allow null parse ?

=head3 maxParses

Returns the number of maximum parse tree valuations. Default is unlimited (i.e. a false value).

=cut

sub maxParses          { 0 }  # Maximum number of parse tree values

=head3 getResult

Returns the current parse tree value.

=cut

sub getResult { $_[0]->[0] }

=head3 setResult

Sets the current parse tree value.

=cut

sub setResult { $_[0]->[0] = $_[1] }

# ----------------
# Specific actions
# ----------------

=head2 Specific actions

=head3 empty_string

Action for rule C<chars ::=>.

=cut

sub empty_string            { ''               } # chars ::=

=head3 unicode

Action for rule C<char ::= /(?:\\u[[:xdigit:]]{4})+/

=cut

sub unicode {
  my ($self, $u) = @_;

  my @hex;
  while ($u =~ m/\\u([[:xdigit:]]{4})/g) {
    push(@hex, hex($1))
  }

  my $result;
  while (@hex) {
    #
    # Surrogate pair ?
    #
    if ($#hex > 0) {
      my ($high, $low) = @hex;
      #
      # Okay... Are these REALLY surrogate pairs ?
      #
      if (($high >= 0xD800) && ($high <= 0xDBFF) && ($low >= 0xDC00) && ($low <= 0xDFFF)) {
        $result .= chr((($high - 0xD800) * 0x400) + ($low - 0xDC00 + 0x10000));
        splice(@hex, 0, 2);
        next
      }
    }
    $result .= chr(shift @hex)
  }

  $result
}

=head3 members

Action for rule C<members  ::= pairs* separator => ','> hide-separator => 1

=cut

sub members {                                   # members  ::= pairs*
    #
    # Arguments are: ($self, $pair1, $pair2, etc..., $pairn)
    #
    shift, +{ map { @{$_} } @_ }
}

=head1 SEE ALSO

L<MarpaX::ESLIF::ECMA404>

=cut

1;
