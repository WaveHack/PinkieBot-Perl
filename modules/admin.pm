package PinkieBot::Module::Admin;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

my $authLoaded = 1;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Warn if module Auth isn't loaded
	unless ($bot->moduleLoaded('auth')) {
		$bot->report("Warning: Module 'Auth' is not loaded or disabled and this module sort of depends on it. Anyone can control the bot without it!", $message);
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
	$self->registerHook('said', \&handleSaidCmd);
	$self->registerHook('said', \&handleSaidEval);
	$self->registerHook('invited', \&handleInvited);
}

sub handleSaidListAvailable {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^list available(?: modules)?$/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 6)); 

	$bot->reply(('Available modules: ' . join(', ', sort($bot->getAvailableModules()))), $message);
}

sub handleSaidListLoaded {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^list loaded(?: modules)?$/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 6)); 

	$bot->reply(('Loaded modules: ' . join(', ', sort($bot->getLoadedModules()))), $message);
}

sub handleSaidListActive {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^list active(?: modules)?$/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 6));

	$bot->reply(('Active modules: ' . join(', ', sort($bot->getLoadedModules()))), $message);
}

sub handleSaidLoadModule {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^load(?: module)? ([^ ]+)(?: (.+))?/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $ret = $bot->loadModule($1, $message, $2);

	$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
}

sub handleSaidUnloadModule {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^unload(?: module)? (.+)/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $module = lc($1);

	# Just because I can
	if ($module eq 'admin') {
		$bot->reply("I can't unload the Admin module, you silly! How else would you control me?", $message);

		$bot->emote(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "giggles and mumbles something about $message->{who} being a silly filly.",
			address => $message->{address}
		);

		return;
	}

	my $ret = $bot->unloadModule($1);

	$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);

#	if ($module eq 'auth') {
#		$bot->reply("Also reloading module Admin to update permissions. Anypony can control me now. :3", $message);
#
#		my $ret = $bot->reloadModule('admin');
#
#		$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
#	}
}

sub handleSaidReloadModule {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^reload(?: module)? ([^ ]+)(?: (.+))?/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $ret = $bot->reloadModule($1, $message, $2);

	$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
}

sub handleSaidEnableModule {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^enable(?: module)? (.+)/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $ret = $bot->enableModule($1);

	$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
}

sub handleSaidDisableModule {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^disable(?: module)? (.+)/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $ret = $bot->disableModule($1);

	$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
}

sub handleSaidModuleLoaded {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^(?:(?:is )?module )?(.+)(?: loaded)\?$/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 6));

	$bot->reply(($bot->moduleLoaded($1) ? 'Yessiree!' : 'Nopie dopie lopie!'), $message);
}

sub handleSaidModuleActive {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^(?:(?:is )?module )?(.+)(?: active)\?$/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 6));

	$bot->reply(($bot->moduleActive($1) ? 'Yessiree!' : 'Nopie dopie lopie!'), $message);
}

sub handleSaidInfo {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^(?:!pinkiebot|pinkiebot\?)$/i);

	$bot->reply($bot->help(), $message);
}

sub handleSaidUpdate {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^update$/));
	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 8));

	# Update from Mercurial
	my @output = `hg pull && hg up`;

	$bot->reply(join('', @output), $message);
}

sub handleSaidCmd {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^cmd (.+)/));

	if (!$bot->moduleLoaded('auth')) {
		$bot->reply("Cmd is disabled when Auth module isn't loaded", $message);
		return;
	}

	return unless ($bot->module('auth')->checkAuthorization($bot, $message, 9));

	my @output = `$1`;
	
	$bot->reply(join('', @output), $message);
}

sub handleSaidEval {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^eval (.+)/));

	if (!$bot->moduleLoaded('auth')) {
		$bot->reply("Eval is disabled when Auth module isn't loaded", $message);
		return;
	}

	return unless ($bot->module('auth')->checkAuthorization($bot, $message, 9));

	eval("$1");

	$bot->reply($@, $message) if $@;;
}

sub handleInvited {
	my ($bot, $message) = @_;

	return if ($bot->moduleLoaded('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	$bot->join_channel($message->{channel});
}

1;
