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
use Scalar::Util qw/looks_like_number/;

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
        $bnf =~ s/$tag//g;
    }
    if ($options{cplusplus_comment}) {
        my $tag = quotemeta('# /* C++ comment */');
        $bnf =~ s/$tag//g;
    }
    if ($options{bignum}) {
        my $tag = quotemeta('# /* bignum */');
        $bnf =~ s/$tag//g;
    }
    #
    # Check that max_depth looks like a number
    #
    my $max_depth = $options{max_depth} //= 0;
    croak "max_depth option does not look like a number" unless looks_like_number $max_depth;
    #
    # And that it is an integer
    #
    $max_depth =~ s/\s//g;
    croak "max_depth option does not look an integer >= 0" unless $max_depth =~  /^\+?\d+/;
    $options{max_depth} = int($max_depth);
    if ($options{max_depth}) {
        my $tag = quotemeta('# /* max_depth */');
        $bnf =~ s/$tag//g;
    }

    bless {
           grammar => MarpaX::ESLIF::Grammar->new(MarpaX::ESLIF->new($options{logger}), $bnf),
           %options
          }, $pkg
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
  my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new($self->{logger});

  # ---------------
  # Parse the input
  # ---------------
  my $max_depth = $self->{max_depth};
  if ($max_depth) {
    $self->{cur_depth} = 0;
    #
    # We need to use the recognizer loop to have access to the inc/dec events
    #
    my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($self->{grammar}, $recognizerInterface);
    return unless eval {
      $eslifRecognizer->scan() || die "scan() failed";
      $self->_manage_events($eslifRecognizer);
      if ($eslifRecognizer->isCanContinue) {
        do {
          $eslifRecognizer->resume || die "resume() failed";
          $self->_manage_events($eslifRecognizer)
        } while ($eslifRecognizer->isCanContinue)
      }
      #
      # We configured value interface to not accept ambiguity not null parse.
      # So no need to loop on value()
      #
      MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface)->value()
    }
  } else {
    return unless $self->{grammar}->parse($recognizerInterface, $valueInterface)
  }

  # ------------------------
  # Return the value
  # ------------------------
  $valueInterface->getResult
}

sub _manage_events {
  my ($self, $eslifRecognizer) = @_;

  foreach (@{$eslifRecognizer->events()}) {
    my $event = $_->{event};
    next unless $event;  # Can be undef for exhaustion
    if ($event eq 'inc[]') {
      croak "Maximum depth $self->{max_depth} reached" if ++$self->{cur_depth} > $self->{max_depth}
    } elsif ($event eq 'dec[]') {
       --$self->{cur_depth}
     }
  }
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
object   ::= '{' inc members '}' dec                                       action => ::copy[2]         # Returns members
members  ::= pairs* separator => comma     proper => 1 hide-separator => 1 action => members           # Returns { @{pairs1}, ..., @{pair2} }
pairs    ::= string ':' value                                              action => pairs             # Returns [ string, value ]
array    ::= '[' inc elements ']' dec                                      action => ::copy[2]         # Returns elements
elements ::= value* separator => comma     proper => 1 hide-separator => 1 action => elements          # Returns [ value1, ..., valuen ]
value    ::= string                                                                                    # ::shift (default action)
           | number                                                                                    # ::shift (default action)
           | object                                                                                    # ::shift (default action)
           | array                                                                                     # ::shift (default action)
           | 'true'                                                        action => true              # Returns a perl true value
           | 'false'                                                       action => false             # Returns a perl false value
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

# ---------------
# Depth extension
# ---------------
inc ::=                                                        action => ::undef
dec ::=                                                        action => ::undef

# /* max_depth */event inc[] = nulled inc                                                        # Increment depth
# /* max_depth */event dec[] = nulled dec                                                        # Decrement depth

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
# number ::= /\-?(?:(?:[1-9]?[0-9]+)|[0-9])(?:\.[0-9]+)?(?:[eE](?:[+-])?[0-9]+)?/ # /* bignum */action => number
number ::= NUMBER # /* bignum */action => number

# /* bignum */number   ::= '-' nan                               action => nan
# /* bignum */number   ::=     nan                               action => nan
# /* bignum */number   ::= '+' nan                               action => nan
# /* bignum */number   ::= '-' infinity                          action => negative_infinity
# /* bignum */number   ::=     infinity                          action => positive_infinity
# /* bignum */number   ::= '+' infinity                          action => positive_infinity
# /* bignum */nan      ::= 'NaN'
# /* bignum */infinity ::= 'Infinity' | 'Inf'

# Original BNF for number follows
#
NUMBER    ~ int
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
digits    ~ digit+
e         ~ /e[+-]?/i
