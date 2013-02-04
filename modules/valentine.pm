package PinkieBot::Module::Valentine;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidValentine);
}

sub handleSaidValentine {
	my ($bot, $message) = @_;

	return unless (
		($message->{body} =~ /(valentine|valentijn)/i)
		&& ($message->{body} =~ /(alone|alleen|eenzaam|commerci\w+)/i)
	);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': http://www.youtube.com/watch?v=Clpw2B7Tr44'),
		address => $message->{address}
	);
}

1;
