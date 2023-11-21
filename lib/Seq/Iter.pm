package Seq::Iter;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(seq_iter);

our $BUFFER_SIZE = 10;

sub seq_iter {
    my @orig_seq = @_;

    my $index = -1;
    my $index_coderef;
    my @gen_seq;
    sub {
        $index++;
        splice @gen_seq, $BUFFER_SIZE-1 if @gen_seq > $BUFFER_SIZE;

      RETRY:
        if (defined $index_coderef) {
            my $item = $orig_seq[$index_coderef]->($index, \@orig_seq, \@gen_seq);
            return unless defined $item;
            unshift @gen_seq, $item;
            return $item;
        } elsif ($index >= @orig_seq) {
            return;
        } else {
            my $item = $orig_seq[$index];
            if (ref $item eq 'CODE') {
                $index_coderef = $index;
                goto RETRY;
            } else {
                unshift @gen_seq, $item;
                return $item;
            }
        }
    };
}

1;
#ABSTRACT: Generate a coderef iterator from a sequence of items, the last of which can be a coderef to produce more items

=for Pod::Coverage .+

=head1 SYNOPSIS

  use Seq::Iter qw(seq_iter);

 # generate fibonacci sequence
 my $iter = seq_iter(1, 1, sub { my ($index, $orig_seq, $gen_seq) = @_; $gen_seq->[0] + $gen_seq->[1] }); # => 1, 1, 2, 3, 5, 8, ...
 # ditto, shorter
 my $iter = seq_iter(1, 1, sub { $_[2][0] + $_[2][1] });

 # generate 5 random numbers
 my $iter = seq_iter(sub { my ($index, $orig_seq, $gen_seq) = @_; $index >= 5 ? undef : sprintf("%.3f", rand()) }); # => 0.238, 0.932, 0.866, 0.841, 0.501, undef, ...

 # randomly decrease between 0.1 and 0.4 then always return 0 after it reaches <= 0
 my $iter = seq_iter(3, sub { my ($index, $orig_seq, $gen_seq) = @_; $gen_seq->[0] <= 0 ? 0 : $gen_seq->[1]-(rand()*0.3+0.1)));


=head1 DESCRIPTION

This module provides a simple (coderef) iterator which you can call repeatedly
to get numbers specified in a sequence specification (list). The last item of
the list can be a coderef which will be called to produce more items. The
coderef item will be called with:

 ($index, $orig_seq, $gen_buf)

where C<$index> is a incrementing number starting from 0 (for the first item of
the generated sequence), C<$orig_seq> is the original sequence arrayref, and
C<$gen_buf> is an array containing generated items (most recent items first),
capped at C<$BUFFER_SIZE> items (by default 10).


=head1 FUNCTIONS

=head2 seq_iter

Usage:

 $iter = seq_iter(LIST); # => coderef


=head1 VARIABLES

=head2 $BUFFER_SIZE


=head1 SEE ALSO

For simpler number sequence, see L<NumSeq::Iter>. As of 0.006, the module
supports recognizing fibonacci sequence.

Other C<*::Iter> modules.

=cut
