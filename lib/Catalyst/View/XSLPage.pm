package Catalyst::View::XSLPage;

use strict;
use warnings;

use base 'Catalyst::View::XSLT';

use XML::LibXML;
use Scalar::Util qw/blessed/;

sub render {
	my $self = shift;
	my ($c, $template, $args) = @_;
	die 'no XML and no page_elements to create the view' unless $c->stash->{xml} or ($c->stash->{page_elements} and keys %{$c->stash->{page_elements}});
	
	my $doc = XML::LibXML::Document->createDocument('1.0', 'utf-8');
	my $page_element = XML::LibXML::Element->new('page');
	$doc->setDocumentElement($page_element);
	
	foreach my $key (keys %{$c->stash->{page_elements}}) {
		my $element = $c->stash->{page_elements}->{$key};
		if (blessed $element and $element->isa('XML::LibXML::Element')) {
			$page_element->appendChild($element);
		}
		else {
			warn "invalid page element for '$key' key";
		}
	}
	
	$c->stash->{xml} = $doc;
	
	if ($c->debug and $c->request->params->{xml}) {
		$c->response->content_type('text/xml');
		return $c->stash->{xml}->serialize(1);
	}
	
	if ($c->debug and $c->request->params->{atom} and exists $c->stash->{page_elements}->{atom}) {
		$c->response->content_type('text/xml');
		return $c->stash->{page_elements}->{atom}->serialize(1);
	}

	$self->NEXT::render(@_);
};

1;
