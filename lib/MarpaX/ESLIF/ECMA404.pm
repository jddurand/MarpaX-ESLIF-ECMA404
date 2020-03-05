=for html <a href="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404"><img src="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404.svg?branch=master" alt="Travis CI build status" height="18"></a> <a href="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404"><img src="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404.svg" alt="GitHub version" height="18"></a> <a href="https://dev.perl.org/licenses/" rel="nofollow noreferrer"><img src="https://img.shields.io/badge/license-Perl%205-blue.svg" alt="License Perl5" height="18">

=cut

use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404;
use Log::Any qw/$log/;
use MarpaX::ESLIF 3.0.32;

my $ESLIF = MarpaX::ESLIF->new($log);

# ABSTRACT: JSON Data Interchange Format following ECMA-404 specification

# VERSION

# AUTHORITY

=head1 DESCRIPTION

This module decodes/encodes strict/relaxed JSON input using L<MarpaX::ESLIF>.

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404 qw//;

    my $input   = '["JSON",{},[]]';
    my $perlvar = MarpaX::ESLIF::ECMA404->decode($input);
    my $string  = MarpaX::ESLIF::ECMA404->encode($perlvar);

=head1 NOTES

This module is nothing else but a proxy to L<MarpaX::ESLIF::JSON>, please refer to the later for the C<decode> and C<encode> methods.

=cut

=head2 decode($self, $input, %options)

=cut

sub decode {
    my ($self, $input, %options) = @_;

    return $options{strict} ? _JSONStrict()->decode($input, %options) : _JSONRelaxed()->decode($input, %options)
}

=head2 encode($self, $input)

=cut

sub encode {
    my ($self, $input, %options) = @_;

    return $options{strict} ? _JSONStrict()->encode($input, %options) : _JSONRelaxed()->encode($input, %options)
}

# -------------
# Private stubs
# -------------
sub _JSONStrict {
    CORE::state $JSONStrict = MarpaX::ESLIF::JSON->new($ESLIF, 1);

    return $JSONStrict
}

sub _JSONRelaxed {
    CORE::state $JSONRelaxed = MarpaX::ESLIF::JSON->new($ESLIF, 0);

    return $JSONRelaxed
}

=head1 SEE ALSO

L<MarpaX::ESLIF::JSON>, L<Log::Any>

=cut

1;
