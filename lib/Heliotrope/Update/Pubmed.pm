package Heliotrope::Update::Pubmed;

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
use Carp;
use File::Find;
use IO::Uncompress::Gunzip;
use Parallel::ForkManager;
use XML::LibXML;
use XML::LibXML::Reader;

use Heliotrope::Registry;
use Heliotrope::Data qw(resolve_references expand_references deep_eq);
use Heliotrope::Util::XMLtoJSON;

$| = 1;

my $MAX_PROCESSES = 12;

my $ELEMENT_LIST_ENTRIES = {
  "/Article/AuthorList/Author" => 1,
  "/Article/Abstract/AbstractText" => 1,
  "/Article/PublicationTypeList/PublicationType" => 1,
  "/Article/DataBankList/DataBank" => 1,
  "/Article/DataBankList/DataBank/AccessionNumberList/AccessionNumber" => 1,
  "/Article/Language" => 1,
  "/Article/ELocationID" => 1,
  "/ChemicalList/Chemical" => 1,
  "/MeshHeadingList/MeshHeading" => 1,
  "/MeshHeadingList/MeshHeading/QualifierName" => 1,
  "/CitationSubset" => 1,
  "/Article/GrantList/Grant" => 1,
  "/OtherID" => 1,
  "/CommentsCorrectionsList/CommentsCorrections" => 1,
  "/KeywordList" => 1,
  "/KeywordList/Keyword" => 1,
  "/GeneralNote" => 1,
  "/InvestigatorList/Investigator" => 1,
  "/SupplMeshList/SupplMeshName" => 1,
  "/PersonalNameSubjectList/PersonalNameSubject" => 1,
  "/GeneSymbolList/GeneSymbol" => 1
};

my $OBJECT_LIST_ENTRIES = {
  "/Article/Abstract/AbstractText" => 1
};

my $DATE_LIST_ENTRIES = {
  "/DateCreated" => 1,
  "/DateCompleted" => 1,
  "/DateRevised" => 1,
  "/Article/ArticleDate" => 1
};

sub BUILD {
    my ($self) = @_;
    $self->{name} = "pubmed";
    $self->{xmltojson} = Heliotrope::Util::XMLtoJSON->new({
      element_list_entries => $ELEMENT_LIST_ENTRIES,
      object_list_entries => $OBJECT_LIST_ENTRIES,
      date_list_entries => $DATE_LIST_ENTRIES
    });
}

sub maybe_update {
    my ($self, $registry, %options) = @_;
    return;
}

sub _handle_file {
    my ($self, $file) = @_;
    return unless ($file =~ /n\d{4,4}\.xml\.gz$/);

    say "$file";

    my $database = $self->open_database();
    my $collection = $database->get_collection('publications');
    $collection->ensure_index({"name" => 1}, { unique => true, sparse => true, safe => true });

    say "Reading $file";
    eval {
        my $fh = IO::Uncompress::Gunzip->new($file);
        my $reader = XML::LibXML::Reader->new(IO => $fh);

        # Skip to first entry element
        while($reader->read() && $reader->name() ne 'MedlineCitation') {};

        do {
            if ($reader->name() eq 'MedlineCitation') {
                entry($self, $collection, $reader)
            }
        } while($reader->nextSibling());

        close($fh);
    };
    if ($@) {
        carp "$@";
    }

    $self->close_database($database);
}

sub entry {
    my ($self, $collection, $reader) = @_;

    my $xml = $reader->readOuterXml();
    my $dom = XML::LibXML->load_xml(string => $xml, clean_namespaces => 1);
    my $root = $dom->documentElement();

    my $pmid = $root->findvalue('/MedlineCitation/PMID');

    my $encoded = $self->{xmltojson}->convert_document_to_json($root);
    $encoded->STORE('PMID', "$pmid");

    my $query = {name => "pmid:$pmid"};

    my $document =  Tie::IxHash->new();
    $document->STORE('id', "pmid:$pmid");
    $document->STORE('name', "pmid:$pmid");
    $document->STORE('sections',  Tie::IxHash->new('pubmed', {"data" => $encoded}));
    my $action = {'$set' => $document};
    my $new_date = $encoded->FETCH('DateRevised') // $encoded->FETCH('DateCompleted') // $encoded->FETCH('DateCreated');

    my $existing = $collection->find_one($query, {_id => true, "sections.pubmed.data" => true});
    if (! $existing) {
    	$collection->insert($document, {w => 1, j => true});
        say "Inserting: pmid:$pmid";
    	$self->{_count}++;
    	return;
    }

    my $existing_data =  $existing->{sections}->{pubmed}->{data};
    my $existing_date = $existing_data->{DateRevised} // $existing_data->{DateCompleted} // $existing_data->{DateCreated};

    if (! $existing_date || ! $new_date) {
        carp("Can't resolve dates: $existing_date, $new_date");
    }
    if (DateTime->compare($existing_date, $new_date) == -1) {
    	$collection->update($query, $action, {w => 1, j => true});
      say "Updating: pmid:$pmid";
    	$self->{_count}++;
    	return;
    } else {
    	$self->{_skip_count}++;
    	return;
    }
}

sub update {
	my ($self, $registry) = @_;

    say "About to update.";

    my $base = $ENV{HELIOTROPE_PUBMED_BASE} || "/Users/swatt/pubmed_xml";
    my @files = ();
    my $wanted = sub {
        push @files, $File::Find::name if ($File::Find::name =~ /n\d{4,4}\.xml\.gz$/);
    };
    my $preprocess = sub {
        my @files = @_;
	   return sort { $a cmp $b } @files;
    };
    find({wanted => $wanted, preprocess => $preprocess, nochdir => 1}, $base);

    my $pm = new Parallel::ForkManager($MAX_PROCESSES);
    foreach my $file (@files) {
        my $pid = $pm->start() and next;
        _handle_file($self, $file);
        $pm->finish();
    };

    $pm->wait_all_children();
}

sub output {
	my ($self, $registry) = @_;

    my $database = $self->open_database();
    my $collection = $database->get_collection('pubmed');

    $collection->ensure_index({"name" => 1}, { unique => true, sparse => true, safe => true });

    my $query = $collection->find({name => {'$exists' => false}}, {PMID => 1});
    my @pmids = ();
    while (my $object = $query->next()) {
        push @pmids, $object->{PMID};
    }

    my $count = @pmids;
    say "About to update $count documents";

    foreach my $pmid (@pmids) {
        my $result = $collection->update({PMID => "$pmid"}, {'$set' => {name => "pmid:$pmid", id => "pmid:$pmid"}}, {w => 1, j => true});
        say "Update: $pmid updated $result->{n} documents";
    }

    $collection->drop_index({name => 1});
    $collection->ensure_index({id => 1});
    $collection->ensure_index({name => 1});

    $self->close_database($database);
}

1;
