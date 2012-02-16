package PinkieBot::Module::Admin;
use base 'PinkieBot::Module';

my $authLoaded = 1;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Check if module Auth is loaded
	if (!$bot->moduleLoaded('auth')) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "\x02Warning\x0F: Module 'Auth' is not loaded or disabled and this module sort of depends on it. Anyone can control the bot without the 'Auth' module!.",
			address => $message->{address}
		);

		$authLoaded = 0;
	}

	# Register hooks
	$self->registerHook('said', \&handleSaidListAvailable);
	$self->registerHook('said', \&handleSaidListLoaded);
	$self->registerHook('said', \&handleSaidListActive);
	$self->registerHook('said', \&handleSaidLoadModule);
	$self->registerHook('said', \&handleSaidUnloadModule);
	$self->registerHook('said', \&handleSaidReloadModule);
	$self->registerHook('said', \&handleSaidDisableModule);
	$self->registerHook('said', \&handleSaidEnableModule);
	$self->registerHook('said', \&handleSaidModuleLoaded);
	$self->registerHook('said', \&handleSaidModuleActive);
	$self->registerHook('said', \&handleSaidInfo);
	$self->registerHook('said', \&handleSaidUpdate);
	$self->registerHook('invited', \&handleInvited);
}

sub handleSaidListAvailable {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!list available$/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Available modules: ' . (join(', ', sort($bot->getAvailableModules())))),
		address => $message->{address}
	);
}

sub handleSaidListLoaded {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!list loaded$/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Loaded modules: ' . (join(', ', sort($bot->getLoadedModules())))),
		address => $message->{address}
	);
}

sub handleSaidListActive {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!list active$/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Active modules: ' . (join(', ', sort($bot->getLoadedModules())))),
		address => $message->{address}
	);
}

sub handleSaidLoadModule {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!load ([^ ]+)(?: (.+))?/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	my $ret = $bot->loadModule($1, $message, $2);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
		address => $message->{address}
	);
}

sub handleSaidUnloadModule {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!unload (.+)/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	my $ret = $bot->unloadModule($1);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
		address => $message->{address}
	);
}

sub handleSaidReloadModule {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!reload ([^ ]+)(?: (.+))?/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	my $ret = $bot->reloadModule($1, $message, $2);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
		address => $message->{address}
	);
}

sub handleSaidEnableModule {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!enable (.+)/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	my $ret = $bot->enableModule($1);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
		address => $message->{address}
	);
}

sub handleSaidDisableModule {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!disable (.+)/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	my $ret = $bot->disableModule($1);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
		address => $message->{address}
	);
}

sub handleSaidModuleLoaded {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!loaded (.+)/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . ($bot->moduleLoaded($1) ? 'Eeeyup' : 'Eeenope')),
		address => $message->{address}
	);
}

sub handleSaidModuleActive {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!active (.*)/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . ($bot->moduleActive($1) ? 'Eeeyup' : 'Eeenope')),
		address => $message->{address}
	);
}

sub handleSaidInfo {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!pinkiebot$/);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $bot->help(),
		address => $message->{address}
	);
}

sub handleSaidUpdate {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!update/);

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	# Update from Mercurial
	@output = `hg pull && hg up`;

	$bot->notice(
		who     => $message->{who},
		channel => $message->{channel},
		body    => join("\n", @output),
		address => $message->{address}
	);
}

sub handleInvited {
	my ($bot, $message) = @_;

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	$bot->join_channel($message->{channel});
}

sub checkAuthorization {
	my ($bot, $message, $level) = @_;

	# If Auth module isn't loaded, we're permitted everything
	return 1 unless ($authLoaded);

	unless ($bot->module('auth')->authorizationLevel($message->{raw_nick}) >= $level) {
		$bot->notice(
			who     => $message->{who},
			channel => $message->{channel},
			body    => 'You are not authorized to perform that command.',
			address => $message->{address}
		);

		return 0;
	}

	return 1;
}

1;
