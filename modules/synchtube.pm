package PinkieBot::Module::Synchtube;
use base 'PinkieBot::Module';

use JSON;
use LWP::UserAgent;

my $ua;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Custom User-Agent to prevent access denied errors based on browser
	# signature (probably libwww-perl UA)
	$ua = LWP::UserAgent->new;
	$ua->agent($bot->{name});

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!(?:synch(?:tube)?|st) (.+)/);
	my $room = $1;

	my $content = $ua->get('http://synchtube.com/api/1/room/' . $room)->content;
	my $response = decode_json($content);

	if (defined($response->{error})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': Synchtube error: ' . $response->{error}),
			address => $message->{address}
		);

		return;
	}

	my $title = $response->{current_media}->{title};
	$title = ((length($title) > 120) ? (substr($title, 0, 117) . '...') : $title);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': '  . $title . ' (http://synchtu.be/' . $room . ')'),
		address => $message->{address}
	);
}

1;
