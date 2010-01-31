package Catalyst::Action::InitPage;

use strict;
use warnings;

use base 'Catalyst::Action';

use XML::LibXML;

sub execute {
    my $self = shift;
    my ($controller, $c) = @_;
    
    $c->stash->{page_elements} = {};

	my $site_element = XML::LibXML::Element->new('site');
	$site_element->setAttribute('name', $c->request->uri->host);
	$c->stash->{page_elements}->{site} = $site_element;

    $self->SUPER::execute(@_);

#	my $user_element = XML::LibXML::Element->new('user');	
#	$c->stash->{page_elements}->{user} = $user_element;
#	if ($c->user_exists) {
#		$user_element->setAttribute('name', $c->user->get("name"));
#		$user_element->setAttribute('openid', $c->user->get("display"));
#	}
#	else {
#		$user_element->setAttribute('name', 'test');
#		$user_element->setAttribute('openid', 'test.ya.ru');		
#	}
}

1;