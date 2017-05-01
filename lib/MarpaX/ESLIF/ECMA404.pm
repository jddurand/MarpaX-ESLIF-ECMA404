use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404;

# ABSTRACT: JSON Data Interchange Format following ECMA-404 specification

# VERSION

# AUTHORITY

use Carp qw/croak/;
use MarpaX::ESLIF 2;
use MarpaX::ESLIF::ECMA404::RecognizerInterface;
use MarpaX::ESLIF::ECMA404::ValueInterface;

our $_ESLIF;                           # Singleton instanciated if needed
our $_DATA = do { local $/; <DATA> };  # JSON grammar

sub new {
    #
    # Without a first parameter, that must be a Log::Any compliant thingy,
    # we will use a grammar generated via a MarpaX::ESLIF singleton
    #
    ($#_ >= 1)
        ?
        bless \MarpaX::ESLIF::Grammar->new(MarpaX::ESLIF->new($_[1]), $_DATA), $_[0]
        :
        bless \MarpaX::ESLIF::Grammar->new(($_ESLIF //= MarpaX::ESLIF->new()), $_DATA), $_[0]
}

sub json_decode {
  my $recognizerInterface = MarpaX::ESLIF::ECMA404::RecognizerInterface->new($_[1]);

  #
  # The only reason why we cannot use the grammar parse() interface is because we
  # have the need for the :discard[on] and :discard[off] events, even if they will NEVER
  # be propagated to user space. Therefore there is NO call to resume() -;
  #
  my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new(${$_[0]}, $recognizerInterface);
  $eslifRecognizer->scan();

  my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new;

  #print STDERR "ATTACH ME: PID $$\n";
  #sleep(10);
  MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface)->value;
  $valueInterface->getResult;
}

1;

__DATA__
#
# JSON starting point is value
#
:start ::= value
# ----------------------------
# JSON Grammar as per ECMA-404
# I explicitely expose string grammar for two reasons:
# - The sub-grammar have inner actions that I want to be executed
# - The only drawback of not using a lexeme is that we have to explicitely disable :discard within string
#   ... This is done with the discardOn and discardOff nullables
# ----------------------------
object   ::= '{' members '}'                         action => ::copy[1] # If nullable, members is an empty hash ref
members  ::= pairs* separator => ','                 action => members
pairs    ::= string ':' value                        action => pairs
array    ::= '[' elements ']'                        action => ::copy[1] # If nullable, elements is an empty array ref
elements ::= value* separator => ','                 action => array_ref
value    ::= string                                  action => ::shift
           | number                                  action => ::shift
           | object                                  action => ::shift
           | array                                   action => ::shift
           | 'true'                                  action => ::shift
           | 'false'                                 action => ::shift
           | 'null'                                  action => ::shift

event :discard[on] = nulled discardOn
discardOn ::=

event :discard[off] = nulled discardOff
discardOff ::=

# -------------------------
# Unsignificant whitespaces
# -------------------------
:discard ::= /[\x{9}\x{A}\x{D}\x{20}]*/

# -----------
# JSON string
# -----------
# Executed in the top grammar and not as a lexeme
#
string  ::= '"' discardOff chars '"' discardOn       action => ::copy[2]               # Only chars is of interest
# Default action is ::concat, that will return undef if there is nothing, so we concat ourself to handle this case
chars   ::= filled                                   action => ::shift
filled  ::= char+                                    action => ::concat                # This is the default action indeed
chars   ::=                                          action => empty_string            # Instead of an undef
char    ::= [^"\\[:cntrl:]]                          action => ::shift                 # Alias to ::copy[0]
          | '\\' '"'                                 action => ::copy[1]               # Faster than a callback to perl
          | '\\' '\\'                                action => ::copy[1]               # Faster than a callback to perl
          | '\\' '/'                                 action => ::copy[1]               # Faster than a callback to perl
          | '\\b'                                    action => backspace_character     # Needs perl chr()
          | '\\f'                                    action => formfeed_character      # Needs perl chr()
          | '\\n'                                    action => newline_character       # Needs perl chr()
          | '\\r'                                    action => return_character        # Needs perl chr()
          | '\\t'                                    action => tabulation_character    # Needs perl chr()
          | '\\u' /[[:xdigit:]]{4}/                  action => hex2codepoint_character # Needs perl chr()
# -----------
# JSON number
# -----------
# Ok to be a lexeme, the final result is always compliant with what perl understands
#
number    ~ int
          | int frac
          | int exp
          | int frac exp
int       ~ digit
          | digit19 digits
          | '-' digit
          | '-' digit19 digits
digit     ~ [[:digit:]]
digit19   ~ [1-9]
frac      ~ '.' digits
exp       ~ e digits
digits    ~ digit*
e         ~ /e[+-]?/i
