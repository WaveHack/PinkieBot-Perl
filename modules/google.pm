package PinkieBot::Module::Google;
use base 'PinkieBot::Module';

use Google::Search;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidWebSearch);
	$self->registerHook('said', \&handleSaidImageSearch);
}

sub handleSaidWebSearch {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!g(?:oogle)? (.+)/);

	my $search = Google::Search->Web(query => $1);
	my $result = $search->first;

	unless (defined($result)) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': Sorry, I can\'t find anything for \'' . $searchTerm . '\' on Google.'),
			address => $message->{address}
		);

		return;
	}

	my $title = $result->title;
	$title =~ s/<b>(.+?)<\/b>/\x02$1\x0F/g;

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . $title . ' - ' . $result->uri),
		address => $message->{address}
	);
}

sub handleSaidImageSearch {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!(?:gi|gimage|googleimages?) (.+)/);

	my $search = Google::Search->Image(query => $1);
	my $result = $search->first;

	unless (defined($result)) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': Sorry, I can\'t find anything for \'' . $searchTerm . '\' on Google Images.'),
			address => $message->{address}
		);

		return;
	}

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . $result->uri),
		address => $message->{address}
	);
}

1;
