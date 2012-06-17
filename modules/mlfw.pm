package PinkieBot::Module::Mlfw;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

use JSON;
use LWP::UserAgent;
use WWW::Shorten::Bitly;

my $ua;

sub init {
	my ($self, $bot, $message, $args) = @_;

	$ua = LWP::UserAgent->new;

	# Register hooks
	$self->registerHook('said', \&handleSaidMLFW);
	$self->registerHook('said', \&handleSaidMLFWRandom);
}

sub handleSaidMLFW {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!mlfw (.+)/);

	my $response = $ua->get('http://mylittlefacewhen.com/api/search/?limit=1&order=random&tags=["' . join('","', split(',', $1)) . '"]');

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

	unless (defined($image) && $image ne '') {
		$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => ($message->{who} . ': Nothing found for \'' . $1 . '\' on MLFW.'),
				address => $message->{address}
		);

		return;
	}

	# Use Bit.ly if we set username/apikey in config
	if (
		defined($bot->{cfg}->val('bitly', 'username')) && ($bot->{cfg}->val('bitly', 'username') ne '') &&
		defined($bot->{cfg}->val('bitly', 'apikey'))   && ($bot->{cfg}->val('bitly', 'apikey') ne '')
	) {
		$image = makeashorterlink($image, $bot->{cfg}->val('bitly', 'username'), $bot->{cfg}->val('bitly', 'apikey'));
	}

	$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': MLFW for \'' . $1 . '\': ' . $image),
			address => $message->{address}
	);
}


sub handleSaidMLFWRandom {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^>mlfw (.+)/);

	my $phrase = $1;

	my $response = $ua->get('http://mylittlefacewhen.com/api/faces/?order=random');

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

	unless (defined($image) && $image ne '') {
		$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => ($message->{who} . ': Error while fetching result.'),
				address => $message->{address}
		);

		return;
	}

	# Use Bit.ly if we set username/apikey in config
	if (
		defined($bot->{cfg}->val('bitly', 'username')) && ($bot->{cfg}->val('bitly', 'username') ne '') &&
		defined($bot->{cfg}->val('bitly', 'apikey'))   && ($bot->{cfg}->val('bitly', 'apikey') ne '')
	) {
		$image = makeashorterlink($image, $bot->{cfg}->val('bitly', 'username'), $bot->{cfg}->val('bitly', 'apikey'));
	}

	$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': Random MLFW for \'' . $phrase . '\': ' . $image),
			address => $message->{address}
	);
}

1;
