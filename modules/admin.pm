#
# This file is part of PinkieBot.
#
# PinkieBot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

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

	return unless ($message->{body} eq '!list available');

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

	return unless ($message->{body} eq '!list loaded');

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

	return unless ($message->{body} eq '!list active');

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

	$module = lc($1);

	if ($module eq 'admin') {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "$message->{who}: Cannot unload Admin module! How else would you control me?!",
			address => $message->{address}
		);

		sleep(2);

		$bot->emote(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "mumbles something about $message->{who} being a silly filly.",
			address => $message->{address}
		);

		return;
	}

	my $ret = $bot->unloadModule($1);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
		address => $message->{address}
	);

	if ($module eq 'auth') {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "$message->{who}: Also reloading Admin module to update permissions. Anypony can control the bot now, have fun!",
			address => $message->{address}
		);

		my $ret = $bot->reloadModule('admin');

		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ": $ret->{string} [Status: $ret->{status}, Code: $ret->{code}]"),
			address => $message->{address}
		);

	}
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

	return unless ($message->{body} eq '!pinkiebot');

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $bot->help(),
		address => $message->{address}
	);
}

sub handleSaidUpdate {
	my ($bot, $message) = @_;

	return unless ($message->{body} eq '!update');

	# Check authorization
	return unless (checkAuthorization($bot, $message, 9));

	# Update from Mercurial
	@output = `hg pull && hg up`;

	$bot->say(
		who     => $message->{who},
		channel => 'msg',
		body    => join('', @output),
		address => 'msg'
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
		$bot->say(
			who     => $message->{who},
			channel => 'msg',
			body    => 'You are not authorized to perform that command.',
			address => 'msg'
		);

		return 0;
	}

	return 1;
}

1;
