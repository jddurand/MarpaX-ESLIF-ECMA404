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

my $_BACKSPACE = chr(0x0008);
my $_FORMFEED  = chr(0x000C);
my $_NEWLINE   = chr(0x000A);
my $_RETURN    = chr(0x000D);
my $_TAB       = chr(0x0009);

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

=head3 hex2codepoint_character($self)

Action for rule C<char ::= '\\' 'u' /[[:xdigit:]]{4}/>.

=cut

sub hex2codepoint_character { chr(hex($_[3]))  } # char  ::= '\\' 'u' /[[:xdigit:]]{4}/

=head3 pairs($self)

Action for rule C<cpairs ::= string ':' value>.

=cut

sub pairs                   { [ $_[1], $_[3] ] } # pairs ::= string ':' value

=head3 backspace_character($self)

Action for rule C<char ::= '\\' 'b'>.

=cut

sub backspace_character     { $_BACKSPACE      } # char  ::= '\\' 'b'

=head3 formfeed_character($self)

Action for rule C<char ::= '\\' 'f'>.

=cut

sub formfeed_character      { $_FORMFEED       } # char  ::= '\\' 'f'

=head3 newline_character($self)

Action for rule C<char ::= '\\' 'n'>.

=cut

sub newline_character       { $_NEWLINE        } # char  ::= '\\' 'n'

=head3 return_character($self)

Action for rule C<char ::= '\\' 'r'>.

=cut

sub return_character        { $_RETURN         } # char  ::= '\\' 'r'

=head3 tabulation_character($self)

Action for rule C<char ::= '\\' 't'>.

=cut

sub tabulation_character    { $_TAB            } # char  ::= '\\' 't'
#
# Methods that need some hacking -;
#
# Separator is PART of the arguments i.e.:
# ($self, $value1, $separator, $value2, $separator, etc...)
#
# C.f. http://www.perlmonks.org/?node_id=566543 for explanation of the method
#

=head3 array_ref($self)

Action for rule C<elements ::= value* separator => ','>.

=cut

sub array_ref {                                 # elements ::= value*
    #
    # elements ::= value+ separator => ','
    #
    # i.e. arguments are: ($self, $value1, $separator, $value2, $separator, etc..., $valuen)
    # Where value is always a token
    #
    [ map { $_[$_*2+1] } 0..int(@_/2)-1 ]
}

=head3 members($self)

Action for rule C<members  ::= pairs* separator => ','>.

=cut

sub members {                                   # members  ::= pairs*
    #
    # members  ::= pairs+ separator => ','
    #
    # i.e. arguments are: ($self, $pair1, $separator, $pair2, $separator, etc..., $pairn)
    #
    my %hash;
    # Where pairs is always an array ref [string,value]
    #
    foreach (map { $_[$_*2+1] } 0..int(@_/2)-1) {
        $hash{$_->[0]} = $_->[1]
    }
    \%hash
}

=head1 SEE ALSO

L<MarpaX::ESLIF::ECMA404>

=cut

1;
