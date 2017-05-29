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

=head3 isWithHighRankOnly($self)

Returns a true or a false value, indicating if valuation should use highest ranked rules or not, respectively. Default is a true value.

=cut

sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?

=head3 isWithOrderByRank($self)

Returns a true or a false value, indicating if valuation should order by rule rank or not, respectively. Default is a true value.

=cut

sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?

=head3 isWithAmbiguous($self)

Returns a true or a false value, indicating if valuation should allow ambiguous parse tree or not, respectively. Default is a false value.

=cut

sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?

=head3 isWithNull($self)

Returns a true or a false value, indicating if valuation should allow a null parse tree or not, respectively. Default is a false value.

=cut

sub isWithNull         { 0 }  # Allow null parse ?

=head3 maxParses($self)

Returns the number of maximum parse tree valuations. Default is unlimited (i.e. a false value).

=cut

sub maxParses          { 0 }  # Maximum number of parse tree values

=head3 getResult($self)

Returns the current parse tree value.

=cut

sub getResult { $_[0]->[0] }

=head3 setResult($self)

Sets the current parse tree value.

=cut

sub setResult { $_[0]->[0] = $_[1] }

# ----------------
# Specific actions
# ----------------

=head2 Specific actions

=head3 empty_string($self)

Action for rule C<chars ::=>.

=cut

sub empty_string            { ''               } # chars ::=

=head3 surrogatepair_character($self)

Action for rule C<char ::= '\\' /(?:u[[:xdigit:]]{4}){2}/

=cut

sub surrogatepair_character_maybe {
  #
  # Just a painful convention -;
  #
  my ($self, $surrogatepair) = @_;
  $surrogatepair =~ /\\u([[:xdigit:]]{4})\\u([[:xdigit:]]{4})/;
  my ($low, $high) = (hex($1), hex($2));
  #
  # Okay... Are these REALLY surrogate pairs ?
  #
  if (($high >= 0xDC00) && ($high <= 0xDFFF) &&
      ($low >= 0xDC00) && ($low <= 0xDFFF)) {
    print STDERR "===> HIGH $1 LOW $2\n";
    return chr((($low - 0xD800) * 0x400) + $high - 0xDC00 + 0x10000 )
  } else {
    return chr(hex($low)) . chr(hex($high))
  }
}

=head3 hex2codepoint_character($self)

Action for rule C<char ::= '\\' 'u' /[[:xdigit:]]{4}/>.

=cut

sub hex2codepoint_character { chr(hex($_[3]))  } # char  ::= '\\' 'u' /[[:xdigit:]]{4}/

=head3 pairs($self)

Action for rule C<cpairs ::= string ':' value>.

=cut

sub pairs                   { [ $_[1], $_[3] ] } # pairs ::= string ':' value

=head3 members($self)

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
