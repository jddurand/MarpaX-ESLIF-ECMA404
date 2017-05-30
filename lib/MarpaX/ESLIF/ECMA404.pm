=for html <a href="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404"><img src="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404.svg?branch=master" alt="Travis CI build status" height="18"></a> <a href="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404"><img src="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404.svg" alt="GitHub version" height="18"></a> <a href="https://dev.perl.org/licenses/" rel="nofollow noreferrer"><img src="https://img.shields.io/badge/license-Perl%205-blue.svg" alt="License Perl5" height="18">

=cut

use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404;

# ABSTRACT: JSON Data Interchange Format following ECMA-404 specification

# VERSION

# AUTHORITY

=head1 DESCRIPTION

This module decodes strict JSON input using L<MarpaX::ESLIF>.

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404;

    my $ecma404 = MarpaX::ESLIF::ECMA404->new();
    my $input   = '["JSON",{},[]]';
    my $json    = $ecma404->decode($input);

=cut

use Carp qw/croak/;
use MarpaX::ESLIF 2.0.12;   # String literal, hide-separator features
use MarpaX::ESLIF::ECMA404::RecognizerInterface;
use MarpaX::ESLIF::ECMA404::ValueInterface;

our $_BNF    = do { local $/; <DATA> };

=head1 SUBROUTINES/METHODS

=head2 new($class, %options)

Instantiate a new object. Takes as parameter an optional hash of options that can be:

=over

=item logger

An optional logger object instance that must do methods compliant with L<Log::Any> interface.

=back

=cut

sub new {
    my ($pkg, %options) = @_;

    my $bnf = $_BNF;
    if ($options{unlimited_commas}) {
        $bnf =~ s/separator => comma/separator => commas/g;
        $bnf =~ s/proper => 1/proper => 0/g;
    }
    if ($options{perl_comment}) {
        my $tag = quotemeta('# /* Perl comment */');
        $bnf =~ s/$tag//;
    }
    if ($options{cplusplus_comment}) {
        my $tag = quotemeta('# /* C++ comment */');
        $bnf =~ s/$tag//;
    }

    bless \MarpaX::ESLIF::Grammar->new(MarpaX::ESLIF->new($options{logger}), $bnf), $pkg
}

=head2 decode($self, $input)

Parses JSON that is in C<$input> and returns a perl variable containing the corresponding structured representation, or C<undef> in case of failure.

=cut

sub decode {
  my ($self, $input) = @_;

  # ----------------------------------
  # Instanciate a recognizer interface
  # ----------------------------------
  my $recognizerInterface = MarpaX::ESLIF::ECMA404::RecognizerInterface->new($input);

  # -----------------------------
  # Instanciate a value interface
  # -----------------------------
  my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new();

  # ---------------
  # Parse the input
  # ---------------
  return unless ${$self}->parse($recognizerInterface, $valueInterface);

  # ------------------------
  # Return the value
  # ------------------------
  $valueInterface->getResult
}

=head1 SEE ALSO

L<MarpaX::ESLIF>, L<Log::Any>

=cut

1;

__DATA__
#
# Default action is to propagate the first RHS value
#
:default ::= action => ::shift
#
# JSON starting point is value
#
:start ::= value
# ----------------------------
# JSON Grammar as per ECMA-404
# I explicitely expose string grammar for one reason: inner string elements have specific actions
# ----------------------------
object   ::= '{' members '}'                                   action => ::copy[1]                     # Returns members
members  ::= pairs* separator => comma     hide-separator => 1 action => members proper => 1           # Returns { @{pairs1}, ..., @{pair2} }
pairs    ::= string ':' value                                  action => ::skip(1)->::[]               # Returns [ string, value ]
array    ::= '[' elements ']'                                  action => ::copy[1]                     # Returns elements
elements ::= value* separator => comma     hide-separator => 1 action => ::[] proper => 1              # Returns [ value1, ..., valuen ]
value    ::= string                                                                                    # ::shift (default action)
           | number                                                                                    # ::shift (default action)
           | object                                                                                    # ::shift (default action)
           | array                                                                                     # ::shift (default action)
           | 'true'                                            action => ::true                        # Returns a perl true value
           | 'false'                                           action => ::false                       # Returns a perl false value
           | 'null'

comma    ::= ','
commas   ::= comma+

# -------------------------
# Unsignificant whitespaces
# -------------------------
:discard ::= /[\x{9}\x{A}\x{D}\x{20}]*/

# ------------------
# Comment extensions
# ------------------
# /* Perl comment */:discard ::= /(?:(?:#)(?:[^\n]*)(?:\n|\z))/u
# /* C++ comment */:discard ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/

# -----------
# JSON string
# -----------
# Executed in the top grammar and not as a lexeme. This is why we shutdown temporarily :discard in it
#
string     ::= '"' discardOff chars '"' discardOn              action => ::copy[2]               # Only chars is of interest
discardOff ::=                                                 action => ::undef                 # Nullable rule used to disable discard
discardOn  ::=                                                 action => ::undef                 # Nullable rule used to enable discard

event :discard[on]  = nulled discardOn                                                           # Implementation of discard disabing using reserved ':discard[on]' keyword
event :discard[off] = nulled discardOff                                                          # Implementation of discard enabling using reserved ':discard[off]' keyword

chars   ::= filled                                                                               # ::shift (default action)
filled  ::= char+                                              action => ::concat                # Returns join('', char1, ..., charn)
chars   ::=                                                    action => empty_string            # Prefering empty string instead of undef
char    ::= [^"\\[:cntrl:]]                                                                      # ::shift (default action)
          | '\\' '"'                                           action => ::copy[1]               # Returns double quote, already ok in data
          | '\\' '\\'                                          action => ::copy[1]               # Returns backslash, already ok in data
          | '\\' '/'                                           action => ::copy[1]               # Returns slash, already ok in data
          | '\\' 'b'                                           action => ::u8"\x{08}"
          | '\\' 'f'                                           action => ::u8"\x{0C}"
          | '\\' 'n'                                           action => ::u8"\x{0A}"
          | '\\' 'r'                                           action => ::u8"\x{0D}"
          | '\\' 't'                                           action => ::u8"\x{09}"
          | /(?:\\u[[:xdigit:]]{4})+/                          action => unicode

# -------------------------------------------------------------------------------------------------------------
# JSON number: defined as a single terminal: ECMA404 numbers can be are 100% compliant with perl numbers syntax
# -------------------------------------------------------------------------------------------------------------
#
number ::= /\-?(?:(?:[1-9]?[0-9]*)|[0-9])(?:\.[0-9]*)?(?:[eE](?:[+-])?[0-9]*)?/                  # ::shift (default action)

# Original BNF for number follows
#
#number    ~ int
#          | int frac
#          | int exp
#          | int frac exp
#int       ~ digit
#          | digit19 digits
#          | '-' digit
#          | '-' digit19 digits
#digit     ~ [[:digit:]]
#digit19   ~ [1-9]
#frac      ~ '.' digits
#exp       ~ e digits
#digits    ~ digit*
#e         ~ /e[+-]?/i
