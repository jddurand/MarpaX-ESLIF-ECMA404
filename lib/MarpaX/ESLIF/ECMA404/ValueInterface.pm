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
#
# ... result getter and setter
#
sub getResult          { $_[0]->[0] }
sub setResult          { $_[0]->[0] = $_[1] }

1;
