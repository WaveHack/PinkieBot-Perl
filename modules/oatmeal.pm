package PinkieBot::Module::Oatmeal;
use base 'PinkieBot::Module';

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidOatmeal);
	$self->registerHook('said', \&handleSaidHavermout);
}

sub handleSaidOatmeal {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /oatmeal/i);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Oatmeal? Are you crazy?!'),
		address => $message->{address}
	);
}

sub handleSaidHavermout {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /havermout/i);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Havermout? Ben je gek?!'),
		address => $message->{address}
	);
}

1;
