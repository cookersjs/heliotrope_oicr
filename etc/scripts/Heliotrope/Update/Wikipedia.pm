package Heliotrope::Update::Wikipedia;

use common::sense;

use MooseX::Singleton;

with 'Heliotrope::Updater';
with 'Heliotrope::Store';

use boolean;
use WWW::Mechanize;
use URI;
use HTTP::Request;
use File::Temp;
use DateTime;
use JSON qw(decode_json);
use Carp;

use Heliotrope::Registry;
use Heliotrope::Data qw(resolve_references expand_references deep_eq);

use MediaWiki::Parser;

sub BUILD {
	my ($self) = @_;
	$self->{name} = "wikipedia";
}

sub maybe_update {
	my ($self, $registry, %options) = @_;
    return;
}

sub update {
	my ($self, $registry) = @_;

    say "About to update.";

    my $mech = WWW::Mechanize->new();

    my $root = URI->new("http://en.wikipedia.org/w/api.php");

    my $url = $root->clone();
    my $query = {action => 'query', format => 'json', list => 'categorymembers', cmtitle => 'Category:Human proteins', cmlimit => 'max'};
    $url->query_form($query);

    my @gene_pages = ();
    while(my $response = $mech->get($url)) {
        my $perl_scalar = decode_json($response->decoded_content());
        push @gene_pages, @{$perl_scalar->{query}->{categorymembers}};
        my $count = @gene_pages;
        say "Found $count genes";

        if ($perl_scalar->{'query-continue'}->{categorymembers}->{cmcontinue}) {
            $query->{cmcontinue} = $perl_scalar->{'query-continue'}->{categorymembers}->{cmcontinue};
            $url->query_form($query);
        } else {
            last;
        }
    }

    # Now we have the page identifiers for all the gene pages. And titles too. We are now in a position
    # where we can start to iterate through these pages and get the textual content, JSON representations, 
    # and so on. 

    my $database = $self->open_database();
    foreach my $gene_page (@gene_pages) {
        _build_article($self, $database, $mech, $root, $gene_page);
    }
    $self->close_database($database);
}

sub _build_article {
    my ($self, $database, $mech, $root, $gene_page) = @_;

    my $url = $root->clone();
    my $query = {action => 'query', prop => 'revisions', format => 'json', rvprop => 'content|tags|timestamp', pageids => $gene_page->{pageid}};
    $url->query_form($query);
    my $response = $mech->get($url);
    my $content = $response->decoded_content();
    my $perl_scalar = decode_json($response->decoded_content());

    my $page_body = $perl_scalar->{query}->{pages}->{$gene_page->{pageid}}->{revisions}->[0]->{"*"};

    # And we're into the Wikipedia handling logic here. This is all getting quote domain-specific.
    my $box_page;
    my @citations;
    my @body;
    my $in_references = 0;

    my $template_handler = sub {
        my ($self, $event, $tag, $body) = @_; 
        if ($tag eq 'PBB') {
            $box_page = $body;
            $box_page =~ s/\|geneid=(\d+)/Template:$tag\/$1/;
        } elsif ($tag eq 'refbegin') {
            $in_references = 1;
        } elsif ($tag eq 'refend') {
            $in_references = 0;
        } elsif ($tag eq 'PBB_Further_reading') {
            $self->parse($body); 
        } elsif ($tag eq 'cite') {
            my $props = $self->unpack_keys($body);
            push @citations, $props if ($in_references);
        }
    };

    my $link_handler = sub { 
        my ($self, $event, $text) = @_; 
        push @body, $text;
    };
    my $text_handler = sub { 
        my ($self, $event, $text) = @_; 
        push @body, $text;
    };

    my $parser = MediaWiki::Parser->new({handlers => {template => $template_handler, link => $link_handler, text => $text_handler}});
    $parser->parse($page_body);

    my $article = {};

    say "$page_body";

    # We don't need everything, but we do want the contents of the PBB template, as this 
    # is provided by Protein Box Bot. This provides the Ensembl gene identifier and a bunch of
    # other useful identifying values. 

    $query = {action => 'query', prop => 'revisions', format => 'json', rvprop => 'content|tags|timestamp', titles => $box_page};
    $url->query_form($query);
    $response = $mech->get($url);
    $content = $response->decoded_content();
    $perl_scalar = decode_json($content);

    my $pages = $perl_scalar->{query}->{pages};
    my @pages = keys %{$pages};
    $box_page_body = $pages->{$pages[0]}->{revisions}->[0]->{"*"};

    my $box_body;
    my $gnf_template_handler = sub {
        my ($self, $event, $tag, $body) = @_; 
        if ($tag eq 'GNF_Protein_box') {
            $box_body = $body;
        }
    };
    $parser = MediaWiki::Parser->new({handlers => {template => $gnf_template_handler}});
    $parser->parse($box_page_body);

    # If there's no box body, quit, as we'll not be able to find an Ensembl ID
    if (! $box_body) {
        say "Missing box. Skipping record.";
        return;
    }

    $box_body =~ s/^\s*\|\s*//s;
    my $keys = $parser->unpack_keys($box_body);

    # Okay, now at this stage we can start processing the links to other items.
    my $gene_id = $keys->{Hs_Ensembl};

    my $existing = $self->find_one_record($database, 'genes', {"id" => $gene_id});
    if (! $existing) {
        say "Can't find gene $gene_id. Skipping record.";
        return;
    }

    # So now we have a gene record, and we can link to that effectively. That will enable
    # references to be resolved. That means we can now begin to assemble the additional
    # gene information, which we can add to the gene page. 

    foreach my $citation (@citations) {
        my $doi = $citation->{doi};
        my $pmid = $citation->{pmid};

        # We can haz PMID. We can now go poke in the database to see if it matches our
        # likely info. 

        say "Found PMID: $pmid";
        my $pubmed = $database->get_collection('pubmed')
    }


    my $new = expand_references($existing);
    $new->{sections}->{wikipedia} = $wikipedia_data;
    my $resolved = resolve_references($new, $existing);
    $self->maybe_write_record($database, 'genes', $resolved, $existing);
}

sub output {
	my ($self, $registry) = @_;
	
    my $cached_data = $self->get_data($registry);
    
}

1;