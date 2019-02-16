package PinkieBot::Module::Slap;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('emoted', \&handleEmote);
}

sub handleEmote {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^slaps ([\w\-_\[\]]+)(.*)/i);
	my $slapped = $1;
	my $args    = $2;

	# Check if the bot got slapped
	if (lc($slapped) eq lc($bot->nick)) {
		$bot->kick(
			$message->{channel},
			$message->{who},
			("Now why would you do that? Slapping me" . $args . "?")
		);
		return;
	}

	# Check if a chanop got slapped, but only if we're not slapping ourselves
	if ((lc($slapped) ne lc($message->{who})) && $bot->pocoirc->is_channel_operator($message->{channel}, $slapped)) {
		$bot->kick(
			$message->{channel},
			$message->{who},
			("Noes! Only I am allowed to slap " . $slapped . $args . " around here!")
		);
		return;
	}
}

1;
