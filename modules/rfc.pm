package PinkieBot::Module::Rfc;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

use LWP::Simple;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!rfc (\d+)$/);

	my $rfc = $1;
	my $url = ('http://tools.ietf.org/html/rfc' . $rfc);

	my $page = get($url);

	unless (defined($page)) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': Sorry, I can\'t find RFC ' . $rfc . '.'),
			address => $message->{address}
		);

		return;
	}

	$page =~ /<title>(.+?)<\/title>/;
	my $title = $1;

	$page =~ /<meta name="DC.Description.Abstract" content="(.+?)" \/>/;
	my $abstract = $1;
	$abstract =~ s/\\n/ /g; # Remove fake newlines
	$abstract =~ s/( {2,})/ /; # Limit spaces to singles

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . $title . ' (' . $url . ')'),
		address => $message->{address}
	);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $abstract,
		address => $message->{address}
	);
}

1;
