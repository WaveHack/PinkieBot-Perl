package PinkieBot::Module::Google;
use base 'PinkieBot::Module';

use Google::Search;
use HTML::Entities;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidWebSearch);
	$self->registerHook('said', \&handleSaidImageSearch);
}

sub handleSaidWebSearch {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!g(?:oogle)? (.+)/);

	my $searchTerm = $1;
	my $search = Google::Search->Web(query => $searchTerm);
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

	my $title = HTML::Entities::decode($result->titleNoFormatting);

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

	my $searchTerm = $1;
	my $search = Google::Search->Image(query => $searchTerm);
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
