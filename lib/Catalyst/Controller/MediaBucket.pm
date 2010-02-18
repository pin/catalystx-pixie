package Catalyst::Controller::MediaBucket;

use warnings;
use strict;

use Class::C3::Adopt::NEXT -no_warn;
use URI::QueryParam;

use Media::Bucket;

use base qw(Catalyst::Controller);

sub new {
	my $class = shift;
	my $self = $class->NEXT::new(@_);
	$self->{bucket} = Media::Bucket->new($self->{bucket_url}, $self->{bucket_path});
	return $self;
}

sub default :Path :ActionClass('InitPage') {
	my ($self, $c) = @_;
	
	my $bucket = $self->{bucket};
	my $id = $bucket->get_id($c->request->uri);
	unless (defined $id) {
		$c->response->status(403);
		$c->response->content_type('text/html');
		my $bucket_uri = $bucket->{uri};
		$c->response->body("Forbidden, please try <a href='$bucket_uri'>$bucket_uri</a>\n");
		return;
	}
	
	my $resource = $bucket->get($c->request->uri);
	if ($resource) {
		if ($resource->isa('Media::Bucket::Resource::Object')) {
			my $file = $resource->{file};
			my $mime_type = $file->get_mime_type();
			$c->response->content_type($mime_type);
			my $th = $c->request->uri->query_param('th');
			if ($th) {
				my $io = $file->get_th_handle($th);
				$c->response->body($io);		
			}
			else {
				my $io = $file->get_handle();
				$c->response->body($io);				
			}
		}
		elsif ($resource->isa('Media::Bucket::Resource::File')) {
			$c->stash->{page_elements}->{atom} = $resource->get_entry()->elem;
			$c->stash->{template} = 'entry.xsl';
		}
		elsif ($resource->isa('Media::Bucket::Resource::Directory')) {
			$c->stash->{page_elements}->{atom} = $resource->get_feed()->elem;
			$c->stash->{template} = 'feed.xsl';
		}
		elsif ($resource->isa('Media::Bucket::Resource::NotFound')) {
			$c->response->status(404);
			$c->response->content_type('text/plain');
			$c->response->body($resource->{message});			
		}
		elsif ($resource->isa('Media::Bucket::Resource::Redirect')) {
			$c->response->redirect($resource->target_uri);
		}
		else {
			die 'hard';
		}
	}
	else {
		$c->response->status(404);
		$c->response->content_type('text/plain');
		$c->response->body("Resource Not Found\n");
	}
}

sub end :ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;