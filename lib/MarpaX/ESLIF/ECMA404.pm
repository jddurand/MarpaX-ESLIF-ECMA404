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
    my $eslifRecognizer     = MarpaX::ESLIF::Recognizer->new(${$_[0]}, $recognizerInterface);

    local $MarpaX::ESLIF::ECMA404::WSok = 1;
    $eslifRecognizer->scan;
    $_[0]->_checkWS($eslifRecognizer);
    while ($eslifRecognizer->isCanContinue) {
        last unless $eslifRecognizer->resume
    }

    my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new;
    MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface)->value;
    $valueInterface->getResult
}

sub _checkWS {
    foreach (@{$_[1]->events}) {
        if ($_->{event} eq 'WS$' && ! $MarpaX::ESLIF::ECMA404::WSok) {
            my ($line, $column) = $_[1]->location;
            croak "Illegal space at line $line" . ($column ? ", column $column" : "")
        }
    }
}

1;

__DATA__
# ----------------------------
# JSON Grammar as per ECMA-404
# I explicitely expose string grammar for two reasons:
# - The sub-grammar have inner actions that I want to be executed
# - The only drawback is that the sub-grammar must not have any whitespace event,
#   this should never happen, and if it happens this will be once only this it is fatal -;
# ----------------------------
object   ::= '{' members '}'
members  ::= pairs+ separator => ','
pairs    ::= string ':' value
array    ::= '[' elements ']'
elements ::= value+ separator => ','
value    ::= string
           | number
           | object
           | array
           | 'true'
           | 'false'
           | 'null'

event trackWS[] = nulled trackWS
trackWS   ::=

event untrackWS[] = nulled untrackWS
untrackWS ::=

# -------------------------
# Unsignificant whitespaces
# -------------------------
WS       ::= /[\x{9}\x{A}\x{D}\x{20}]*/
:discard ::= WS event => WS$

# ----------------------
# JSON value sub-grammar
# ----------------------
#
# Intentionnaly there is no :discard rule
# It could have been writen without action, but there is some
# interpretation to do with the string rule
#
string  ::= '"' trackWS chars untrackWS '"'
chars   ::= char*
char    ::= [^"\\[:cntrl:]] # any Unicode character except "  or \ or control-character  action => ::shift
          | '\\' '"'                                                                     action => ::copy[1]
          | '\\' '\\'                                                                    action => ::copy[1]
          | '\\' '/'                                                                     action => ::copy[1]
          | '\\b'                                                                        action => backspace_character
          | '\\f'                                                                        action => formfeed_character
          | '\\n'                                                                        action => newline_character
          | '\\r'                                                                        action => return_character
          | '\\t'                                                                        action => tabulation_character
          | '\\u' /[[:xdigit:]]{4}/                                                      action => hex2codepoint_character
number  ::= int
          | int frac
          | int exp
          | int frac exp 
int     ::= digit
          | digit19 digits
          | '-' digit
          | '-' digit19 digits
digit   ::= [[:digit:]]
digit19 ::= [1-9]
frac    ::= '.' digits
exp     ::= e digits
digits  ::= digit*
e       ::= 'e'
          | 'e+'
          | 'e-'
          | 'E'
          | 'E+'
          | 'E-'
