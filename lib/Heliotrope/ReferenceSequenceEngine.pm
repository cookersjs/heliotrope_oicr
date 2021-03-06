package Heliotrope::ReferenceSequenceEngine;

## Copyright 2014(c) The Ontario Institute for Cancer Research. All rights reserved.
##
## This program and the accompanying materials are made available under the terms of the GNU Public
## License v3.0. You should have received a copy of the GNU General Public License along with this
## program. If not, see <http://www.gnu.org/licenses/>.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
## IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
## FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
## CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
## DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
## DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
## WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
## WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use common::sense;

use Moose;

use File::Spec;
use File::HomeDir;
use File::Temp;
use IO::CaptureOutput qw(capture);

use Heliotrope::Config;

use Bio::DB::Fasta;

has reference_fh => (
    is  => 'rw'
);

has reference_requests => (
    is  => 'rw'
);

has fasta_path => (
    is  => 'rw'
);

sub clear {
    my ($self) = @_;
    my $config = Heliotrope::Config::get_config();
    $self->reference_requests([]);
    my $path = $config->{fasta_path} || File::Spec->rel2abs("fasta", File::HomeDir->my_home());
    $self->fasta_path($path);
}

sub BUILD {
    my ($self) = @_;
    $self->clear();
}

sub add_reference_sequence_request {
    my ($self, $chromosome, $start, $stop) = @_;
    push @{$self->reference_requests()}, [$chromosome, $start, $stop];
}

sub get_reference_sequences {
    my ($self, $callback) = @_;

    my $fasta_dir = $self->fasta_path();
    my $db = Bio::DB::Fasta->new($fasta_dir);

    foreach my $request (@{$self->reference_requests()}) {
        my $chromosome = $request->[0];
        $chromosome =~ s{^chr}{};
        my $start = $request->[1];
        my $stop = $request->[2];
        my $reference_allele = $db->seq($chromosome, $start, $stop);
        &$callback($chromosome, $start, $stop, $reference_allele);
    }

    $self->clear();
}

1;

=head1 NAME

Heliotrope::ReferenceSequenceEngine

=head1 SYNOPSIS

  use Heliotrope::ReferenceSequenceEngine;
  
  my $engine = Heliotrope::ReferenceSequenceEngine->new();
  $engine->add_reference_sequence_request('1', 2000, 2002);
  $engine->add_reference_sequence_request('X', 2000, 2002);
  
  $engine->get_reference_sequences(sub { 
      my ($ch, $start, $stop, $reference_allele) = @_; 
      say "$ch, $start, $stop, $reference_allele";
  });

=head1 DESCRIPTION

Abstracts logic to find a reference sequence for a part of a chromosome. This
is used when the data we have does not include a reference sequence, just
variant information -- or when we cannot trust the reference sequence
that we do have. 

The API is designed to allow a batch script to process a large number of 
requests. It is not a good idea to assume that there is any ordering applied
consistently to the results. All that can be assumed is that we *might*
get back the corresponding chromosome section back.

Note that chromosomes are coded 1 to 22, X, Y, MT.

=head1 NOTES

Originally implemented as a thin wrapper around Annovar's retrieve_seq_from_fasta.pl 
script. This was replaced by direct use of BioPerl, which makes it consistent with
Ensembl, and easier to install with reasonable licensing.  

Locates fasta files using either the HELIOTROPE_FASTA_DIRECTORY enviroment variable, or in an 
"fasta" directory within the user's home directory. 

=head1 AUTHOR

Stuart Watt E<lt>stuart.watt@oicr.on.caE<gt>

=head1 COPYRIGHT AND LICENSE

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

