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
	my $buckets = {};
	foreach my $bucket_url (keys %{$self->{bucket}}) {
		unless (exists $self->{bucket}->{$bucket_url}->{path}) {
			warn "missing path for bucket $bucket_url";
			next;			
		}
		my $bucket_path = $self->{bucket}->{$bucket_url}->{path};
		my $bucket_owner = exists $self->{bucket}->{$bucket_url}->{owner} ? $self->{bucket}->{$bucket_url}->{owner} : undef;
		$buckets->{$bucket_url} = Media::Bucket->new($bucket_url, $bucket_path, $bucket_owner);
	}
	$self->{buckets} = $buckets;
	return $self;
}

sub default :Path :ActionClass('InitPage') {
	my ($self, $c) = @_;
	
	my $bucket, my $id;
	foreach my $b (values %{$self->{buckets}}) {
		$id = $b->get_id($c->request->uri);
		if (defined $id) {
			$bucket = $b;
			last;
		}
	}
	unless (defined $id) {
		$c->response->status(403);
		$c->response->content_type('text/html');
		$c->response->body("Forbidden (bucket not configured here)\n");
		return;
	}
	
	my $user = eval {$c->user_exists ? $c->user->get("display") : undef};
	
	my $resource = $bucket->get($c->request->uri, $user);
	if ($resource) {
		if ($resource->isa('Media::Bucket::Resource::Object')) {
			my $file = $resource->{file};
			my $mime_type = $file->get_mime_type();
			$c->response->content_type($mime_type);
			my $modification_time = $file->get_modification_time();
			my $last_modified_http_time = HTTP::Date::time2str($modification_time);
			$c->response->header('Last-Modified', $last_modified_http_time);
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
#			$c->response->content_type('text/plain');
#			$c->response->body($resource->{message});	
			$c->stash->{template} = 'common.xsl';		
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