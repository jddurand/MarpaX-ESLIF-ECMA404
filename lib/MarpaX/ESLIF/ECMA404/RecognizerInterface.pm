use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::RecognizerInterface;

# ABSTRACT: MarpaX::ESLIF::ECMA404 Recognizer Interface

# VERSION

# AUTHORITY

# -----------
# Constructor
# -----------
sub new                    { my ($pkg, $string) = @_; bless \$string, $pkg }

# ----------------
# Required methods
# ----------------
sub read                   {                         1 } # First read callback will be ok
sub isEof                  {                         1 } # ../. and we will say this is EOF
sub isCharacterStream      {                         1 } # MarpaX::ESLIF will validate the input
sub encoding               {                           } # Let MarpaX::ESLIF guess
sub data                   { my ($self) = @_; ${$self} } # Data itself
sub isWithDisableThreshold {                         0 } # Disable threshold warning ?
sub isWithExhaustion       {                         0 } # Exhaustion event ?
sub isWithNewline          {                         1 } # Newline count ?
sub isWithTrack            {                         1 } # Absolute position tracking ?

1;
