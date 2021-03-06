package Heliotrope::Update::Entrez;

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

use MooseX::Singleton;

with 'Heliotrope::Updater';
with 'Heliotrope::Store';

use boolean;
use DBI;
use HTTP::Request;
use File::Slurp;
use File::Temp;
use DateTime;
use Carp;
use IO::File;
use List::MoreUtils qw(firstidx apply);
use File::Listing qw(parse_dir);
use XML::LibXML;
use XML::LibXML::Reader;

use Heliotrope::Logging qw(get_logger);
use Heliotrope::Registry;
use Heliotrope::Data qw(resolve_references expand_references deep_eq);

my $log = get_logger();

sub BUILD {
	my ($self) = @_;
	$self->{name} = "entrez";
}

sub maybe_update {
	my ($self, $registry, %options) = @_;

	my ($req, $result, $file);

    my $base_url = "ftp://ftp.ncbi.nih.gov/gene/DATA";
    $req = HTTP::Request->new(GET => "$base_url/ASN_BINARY/Mammalia/");
    $req->header(Accept => "text/plain, */*;q=0.1");
    ($result, $file) = $self->get_resource($registry, $req);
    my @files = parse_dir(read_file($file));

    my ($record) = grep { $_->[0] eq 'Homo_sapiens.ags.gz' } @files;

    my $dt = DateTime->from_epoch(epoch => $record->[3]);
    my $normalized_date = $dt->format_cldr("yyyy-MM-dd");
    $log->debugf("Normalized date: %s", $normalized_date);

    my $cached_data = $self->get_data($registry);
    my $existing = $self->get_target_file($registry, "Homo_sapiens.ags.gz");

    if (! -e $existing) {
        $cached_data = {};
    }

    if (exists($cached_data->{date}) && $cached_data->{date} ge $normalized_date) {
        $log->info("Existing file is newer");
        $log->info("Skipping update");
        return;
    }

    my $entrez_url = $base_url . "/ASN_BINARY/Mammalia/Homo_sapiens.ags.gz";
    $log->infof("Downloading: %s", $entrez_url);
    $req = HTTP::Request->new(GET => $entrez_url);
    ($result, $file) = $self->get_resource($registry, $req);
    $log->info("Download complete");

    # Now we can store the data file in the right place and update the cache
    $cached_data->{date} = $normalized_date;
    $cached_data->{url} = $entrez_url;
    $cached_data->{download_time} = DateTime->now()->iso8601();
    $self->relocate_file($registry, $file, "Homo_sapiens.ags.gz");
    $self->set_data($registry, $cached_data);

    $self->update($registry);
}

sub update {
	my ($self, $registry) = @_;

    $log->info("About to update");
    $self->output($registry);
}

sub output {
	my ($self, $registry) = @_;

    my $cached_data = $self->get_data($registry);

    my ($data_file) = $self->get_target_file($registry, "Homo_sapiens.ags.gz");

    # Trim off the final .gz
    $data_file =~ s{\.gz}{};

    # Get the input stream
    my $command = qq{gene2xml -i '$data_file' -b T -c T};
    open(my $fh, "-|", $command) or die("Can't run command: $command: $!");

    my $reader = XML::LibXML::Reader->new(IO => $fh);

    my $database = $self->open_database();

    # Skip to first entry element
    while($reader->read() && $reader->name() ne 'Entrezgene') {};

    do {
        if ($reader->name() eq 'Entrezgene') {
            entry($self, $database, $cached_data, $reader)
        }
    } while($reader->nextSibling());

    close($fh);
    $self->close_database($database);
}

sub entry {
    my ($self, $database, $cached_data, $reader) = @_;

    my $root = $reader->copyCurrentNode(1);

    my $name = $root->findvalue(qq{/Entrezgene-Set/Entrezgene/Entrezgene_gene/Gene-ref/Gene-ref_locus});
    if (! $name) {
    	return;
    }

    my @ensembl_ids = $root->find(qq{/Entrezgene-Set/Entrezgene/Entrezgene_gene/Gene-ref/Gene-ref_db/descendant-or-self::Object-id_str[string(../../../Dbtag_db) = 'Ensembl']})->to_literal_list();
    my @hgnc_ids = $root->find(qq{/Entrezgene-Set/Entrezgene/Entrezgene_gene/Gene-ref/Gene-ref_db/descendant-or-self::Object-id_id[string(../../../Dbtag_db) = 'HGNC']})->to_literal_list();
    my $summary = $root->findvalue(qq{/Entrezgene-Set/Entrezgene/Entrezgene_summary});
    return unless @ensembl_ids || @hgnc_ids;

    my $entrez_alert = {
        level => "note",
        author => "entrez",
        text => "This information has been updated from Entrez on: $cached_data->{date}",
        date => DateTime->now()
    };

    my $changes = {};
    $changes->{'$inc'}->{version} = 1;
    $changes->{'$set'}->{'sections.description.data.summary'} = $summary;
    $changes->{'$addToSet'}->{'sections.description._alerts'} = $entrez_alert;

    my $selector = {};
    if (@ensembl_ids) {
      $selector->{'id'} = {'$in' => \@ensembl_ids};
      $log->debugf("Updating: Ensembl IDs: %s", join(', ', @ensembl_ids));
    } elsif (@hgnc_ids) {
      $selector->{'sections.identifiers.data.hgnc'} = {'$in' => \@hgnc_ids};
      $log->debugf("Updating: HGNC IDs: %s", join(', ', @hgnc_ids));
    }

    my $result = $self->update_record($database, 'genes', $selector, $changes, {upsert => 0, multiple => 1, w => 1, j => true});
}

1;
