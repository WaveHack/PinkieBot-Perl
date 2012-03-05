package PinkieBot::Module::Title;
use base 'PinkieBot::Module';

use URI::Title 'title';

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /((?:https?:\/\/|www\.)[-~=\\\/a-zA-Z0-9\.:_\?&%,#\+]+)/);
	return if ($1 eq '');

	my $title = title($1);
	return unless defined($title);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "[ $title ]",
		address => $message->{address}
	);
}

1;
