package PinkieBot::Module::Mlfw;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

use JSON;
use LWP::UserAgent;

my $ua;

sub init {
        my ($self, $bot, $message, $args) = @_;

		$ua = LWP::UserAgent->new;

        # Register hooks
        $self->registerHook('said', \&handleSaid);
}

sub handleSaid {
        my ($bot, $message) = @_;

        return unless ($message->{body} =~ /^!mlfw (.+)/);

        my $tag = $1;

		my $response = $ua->get('http://mylittlefacewhen.com/api/search/?limit=1&order=random&tags=["' . $tag . '"]');

		unless ($response->is_success && ($response->code == 200)) {
			$bot->say(
					who     => $message->{who},
					channel => $message->{channel},
					body    => ($message->{who} . ': Error while fetching result.'),
					address => $message->{address}
			);

			return;
		}

		my $image = decode_json($response->decoded_content)->[0]{image};

		unless ($image ne '') {
			$bot->say(
					who     => $message->{who},
					channel => $message->{channel},
					body    => ($message->{who} . ': Nothing found for \'' . $tag . '\' on MLFW.'),
					address => $message->{address}
			);

			return;
		}

        $bot->say(
                who     => $message->{who},
                channel => $message->{channel},
                body    => ($message->{who} . ': MLFW for \'' . $tag . '\': ' . $image),
                address => $message->{address}
        );
}

1;
