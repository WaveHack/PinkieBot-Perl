package PinkieBot::Module::Moon;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

sub init {
	my ($self, $bot, $message, $args) = @_;

	unless ($bot->moduleLoaded('auth') && $bot->moduleLoaded('admin')) {
		# If $message is defined, we're calling it from IRC. Else it's from
		# autoloading. Don't try to say() command there since we're obviously
		# not connected to IRC yet.
		if (defined($message)) {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "\x02Warning\x0F: Cannot load module without modules 'Auth' and 'Admin' loaded!",
				address => $message->{address}
			);

		# Autoload, print to CLI only
		} else {
			print "\nWarning: Cannot load module without modules 'Auth' and 'Admin' loaded!\n";
		}

		$bot->unloadModule('moon');
		return;
	}

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

# Responds to simple greetings
sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!moon (.+)/i);
	return unless ($bot->module('admin')->checkAuthorization($bot, $message, 9));

	my $target = $1;

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ("Grab my tail, " . $target . "!"),
		address => $message->{address}
	);

	sleep(2);

	$bot->pocoirc->kick($message->{channel}, $target, "To the moon!");
}

1;
