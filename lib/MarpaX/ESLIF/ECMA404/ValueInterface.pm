use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::ValueInterface;

# ABSTRACT: MarpaX::ESLIF::ECMA404 Value Interface

# VERSION

# AUTHORITY

# -----------
# Constructor
# -----------
sub new                { bless [], $_[0] }

# ----------------
# Required methods
# ----------------
sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?
sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?
sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?
sub isWithNull         { 0 }  # Allow null parse ?
sub maxParses          { 0 }  # Maximum number of parse tree values

# ----------------
# Specific actions
# ----------------
sub empty_string            { ''               }
sub backspace_character     { chr(0x0008)      }
sub formfeed_character      { chr(0x000C)      }
sub newline_character       { chr(0x000A)      }
sub return_character        { chr(0x000D)      }
sub tabulation_character    { chr(0x0009)      }
sub hex2codepoint_character { chr(oct("0x$_[2]")) }
sub empty_array_ref         { []               }
sub pairs                   { [ $_[1], $_[3] ] }
sub empty_hash_ref          { {}               }
#
# ... Methods that need some hacking -;
#
# Separator is PART of the arguments i.e.:
# ($self, $value1, $separator, $value2, $separator, etc...)
#
# C.f. http://www.perlmonks.org/?node_id=566543 for explanation of the method
#
sub array_ref {
  #
  # elements ::= value+ separator => ','
  #
  # Where value is always a token
  #
  [ map { $_[$_*2+1] } 0..int(@_/2)-1 ]
}

sub members {
  #
  # members  ::= pairs+ separator => ','
  #
  my %hash;
  # Where pairs is always an array ref [string,value]
  #
  foreach (map { $_[$_*2+1] } 0..int(@_/2)-1) {
    use Data::Dumper;
    print STDERR Dumper($_);
    $hash{$_->[0]} = $_->[1]
  }
  \%hash
}

#
# ... result getter and setter
#
sub getResult          { $_[0]->[0] }
sub setResult          { $_[0]->[0] = $_[1] }

1;
