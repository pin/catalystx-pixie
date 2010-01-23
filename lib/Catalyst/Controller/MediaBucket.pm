package Catalyst::Controller::MediaBucket;

use warnings;
use strict;

use Class::C3::Adopt::NEXT -no_warn;

use Media::Bucket;

use base qw(Catalyst::Controller);

sub new {
	my $class = shift;
	my $self = $class->NEXT::new(@_);
	$self->{bucket} = Media::Bucket->new($self->{bucket_url}, $self->{bucket_path});
	return $self;
}

sub default :Path {
	my ($self, $c) = @_;
	
	my $bucket = $self->{bucket};
	my $id = $bucket->get_id($c->request->uri);
	unless (defined $id) {
		$c->response->status(403);
		$c->response->content_type('text/html');
		my $bucket_uri = $bucket->{uri};
		$c->response->body("Forbidden, try <a href='$bucket_uri'>$bucket_uri</a>\n");
		return;
	}
	my $resource = $bucket->get_resource($id);
	if ($resource) {
		if ($resource->isa('Media::Bucket::Resource::Directory')) {
			if ($id =~ /\/$/ or not $id) {
				$c->response->body($resource->get_feed()->as_xml());
			}
			else {
				$c->response->redirect($resource->uri . '/');				
			}
		}
		elsif ($resource->isa('Media::Bucket::Resource::File')) {
			my $mime_type = $resource->get_mime_type();
			$c->response->content_type($mime_type);
			my $io = $resource->get_handle();
			$c->response->body($io);
		}
		else {
			die 'hard';
		}
	}
	else {
		my @resources = $bucket->list_resources($id);
		if (@resources) {
			if (scalar @resources == 1) {
				$resource = $resources[0];
				if ($resource->isa('Media::Bucket::Resource::Directory')) {
					$c->response->redirect($resource->uri);
				}
				elsif ($resource->isa('Media::Bucket::Resource::File')) {
					if ($resource->{id} =~ /(.+)\./g) {
						my $hub_id = $1;
						if ($id eq $hub_id) {
							$c->response->body($resource->get_entry()->as_xml());
						}
						else {
							$c->response->redirect($resource->uri); # TODO: Should redirect to hub
						}
					}
				}
			}
			else {
				$c->response->status(404);
				$c->response->content_type('text/plain');
				$c->response->body("Resource Not Found\n");
			}
		}
		else {
			$c->response->status(404);
			$c->response->content_type('text/plain');
			$c->response->body("Resource Not Found\n");
		}
	}
}

sub end :ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;