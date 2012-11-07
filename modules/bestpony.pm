package PinkieBot::Module::Bestpony;
use base 'PinkieBot::Bestpony';
use warnings;
no warnings 'redefine';
use strict;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /octavia is best pony/i);
	return if ($message->{who} =~ /th?eapot/i);

	$bot->mode($message->{channel} . ' +v ' . $message->{who});
}

1;
