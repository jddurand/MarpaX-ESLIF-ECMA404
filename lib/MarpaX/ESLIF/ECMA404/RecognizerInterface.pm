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
sub read                   {                         1 }
sub isEof                  {                         1 } # End of data ?
sub isCharacterStream      {                         1 } # Character stream ?
sub encoding               {                           } # Encoding ?
sub data                   { my ($self) = @_; ${$self} } # Data
sub isWithDisableThreshold {                         0 } # Disable threshold warning ?
sub isWithExhaustion       {                         0 } # Exhaustion event ?
sub isWithNewline          {                         0 } # Newline count ?
sub isWithTrack            {                         0 } # Absolute position tracking ?

1;
