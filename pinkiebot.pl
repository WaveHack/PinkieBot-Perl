#!/usr/bin/perl

# This program is free software: you can redistribute it and/or modify
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

package PinkieBot;
use base 'Bot::BasicBot';
use Config::IniFiles;
use POE;
use DBI;

use warnings;
use strict;

my $version = '2.0.0';
my $botinfo = ('PinkieBot v' . $version . ' by WaveHack. See https://bitbucket.org/WaveHack/pinkiebot/ for more info, command usage and source code.');

# --- Initialization ---

print "PinkieBot v" . $version . " started\n";

print "Loading config\n";

unless (-e 'pinkiebot.ini') {
	print "No configuration file found. Creating one with placeholder variables. Please\n"
	    , "modify pinkiebot.ini and restart the bot.\n";

	my $cfg = Config::IniFiles->new();
	$cfg->newval('mysql', 'host', 'localhost');
	$cfg->newval('mysql', 'username', 'root');
	$cfg->newval('mysql', 'password', '');
	$cfg->newval('mysql', 'database', 'pinkiebot');
	$cfg->newval('irc', 'nick', ('PinkieBot-' . int(rand(89999) + 10000)));
	$cfg->newval('irc', 'nickpass', '');
	$cfg->newval('irc', 'server', 'irc.example.net');
	$cfg->newval('irc', 'port', 6667);
	$cfg->newval('irc', 'channels', '#channel');
	$cfg->SetParameterComment('irc', 'channels', 'Separate multiple channels with spaces');
	$cfg->newval('irc', 'autoload', 'auth admin');
	$cfg->SetParameterComment('irc', 'autoload', 'Autoload modules on start, separate with spaces');
	$cfg->WriteConfig('pinkiebot.ini');
	exit;
}

my $cfg = Config::IniFiles->new(-file => 'pinkiebot.ini');

# --- Create and start bot ---

print "Initializing bot\n";

my $bot = PinkieBot->new(
	server   => $cfg->val('irc', 'server'),
	port     => $cfg->val('irc', 'port', '6667'),
	channels => [split(' ', $cfg->val('irc', 'channels'))],
	nick     => $cfg->val('irc', 'nick'),
	name     => ('PinkieBot v' . $version)
);

# moduleList holds an array of module names we have loaded. Iterating through
# the modules hash for said gives us an infinite loop somehow, so we keep track
# of them in this array instead.
$bot->{moduleList} = ();
$bot->{modules}    = {};

$bot->{cfg} = $cfg;

# PinkieBot uses a hardcoded MySQL link. She used to use SQLite, but I changed
# it a few revisions ago. Maybe I'll move the database link and the config stuff
# over to its own module later.

print "Creating database link\n";

$bot->{db} = DBI->connect(sprintf('DBI:mysql:%s;host=%s', $bot->{cfg}->val('mysql', 'database'), $bot->{cfg}->val('mysql', 'host')), $bot->{cfg}->val('mysql', 'username'), $bot->{cfg}->val('mysql', 'password'), {'mysql_enable_utf8' => 1}) or die($DBI::errstr . "\n");
$bot->{db}->do('SET NAMES utf8');

# Autoload modules if any (set in config)
if ($cfg->val('irc', 'autoload') ne '') {
	foreach (split(' ', $cfg->val('irc', 'autoload'))) {
		print "Auto-loading module '$_'...";

		my $ret = $bot->loadModule($_);

		if ($ret->{status} == 0) {
			print " ERROR: {$ret->{string}}\n";
		} else {
			print " done\n";
		}
	}
}

print "Starting bot\n";

$bot->run();

# --- Overridden Bot::BasicBot methods ---

sub connected {
	my $self = shift;

	print "Connected\n";

	# NickServ auth
	if ($self->{cfg}->val('irc', 'nickpass') ne '') {
		print "Authenticating\n";
		$self->say(
			channel => 'nickserv',
			body    => ('identify ' . $self->{cfg}->val('irc', 'nickpass'))
		);
	}

	$self->processHooks('connected');
}

sub said        { $_[0]->processHooks('said'       , $_[1]); return; }
sub emoted      { $_[0]->processHooks('emoted'     , $_[1]); return; }
sub noticed     { $_[0]->processHooks('noticed'    , $_[1]); return; }
sub chanjoin    { $_[0]->processHooks('chanjoin'   , $_[1]); return; }
sub chanpart    { $_[0]->processHooks('chanpart'   , $_[1]); return; }
sub topic       { $_[0]->processHooks('topic'      , $_[1]); return; }
sub nick_change { $_[0]->processHooks('nick_change', ($_[1], $_[2])); return; }
sub kicked      { $_[0]->processHooks('kicked'     , $_[1]); return; }
sub userquit    { $_[0]->processHooks('userquit   ', $_[1]); return; }
sub help        { return $botinfo; }

# --- Bot Functions ---

# Returns an array with all available modules. A file ending in .pm in /modules/
# classifies as an available module.
sub getAvailableModules {
	my $self = shift;

	my @availableModules = glob('modules/*.pm');
	foreach (@availableModules) {
		$_ =~ s/modules\/(.*)\.pm/$1/;
	}

	return @availableModules;
}

# Returns an array of currently loaded modules (both active and inactive ones)
sub getLoadedModules {
	my $self = shift;
	return @{$self->{moduleList}};
}

# Returns an array of active modules
sub getActiveModules {
	my $self = shift;

	my @activeModules;
	foreach my $module (@{$self->{moduleList}}) {
		next if ($self->{modules}->{$module}->{enabled} == 0);

		push(@activeModules, $module);
	}

	return @activeModules;
}

# Loads a module. The require() part is done in an eval{} block to catch parse
# errors (Perl ftw!) so the mane thread doesn't break when reloading broken
# module files.
sub loadModule {
	my ($self, $module) = @_;
	my $moduleKey = lc($module);

	# Check if module already loaded
	if ($self->{modules}->{$moduleKey}) {
		return { status => 0, code => 0, string => "Module '$module' already loaded (try reloading)" };
	}

	# Check if module file exists
	unless (-e './modules/' . $moduleKey . '.pm') {
		return { status => 0, code => 1, string => "Module '$module' not found" };
	}

	my $modulePackage = ("PinkieBot::Module::" . ucfirst($module));

	# Remove package from %INC if it exists so we don't get the cached version.
	# This forces require() to actually re-parse the file again.
	delete $INC{'./modules/' . $moduleKey . '.pm'};

	# Include file and set up object in an eval{} block so we can catch parse
	# errors in module files
	eval {
		require('./modules/' . $moduleKey . '.pm');

		$self->{modules}->{$moduleKey}->{object} = $modulePackage->new($self);
		$self->{modules}->{$moduleKey}->{enabled} = 1;

		push(@{$self->{moduleList}}, $moduleKey);
	};

	# Return error if the eval{} block above failed (due parse error most
	# likely)
	if ($@) {
		return { status => 0, code => 2, string => $@ };
	}

	# No perse errors, return success. Huzzah!
	return { status => 1, code => -1, string => "Module '$module' loaded" };
}

# Unloads a module (if loaded) and reloads it. Note that non-stored variables
# are not kept and the whole init()itialization function is called again.
sub reloadModule {
	my ($self, $module) = @_;

	$self->unloadModule($module);
	$self->loadModule($module);

	return { status => 1, code => -1, string => "Module '$module' reloaded" };
}

# Unloads a module from memory.
sub unloadModule {
	my ($self, $module) = @_;
	my $moduleKey = lc($module);

	unless ($self->{modules}->{$moduleKey}) {
		return { status => 0, code => 0, string => "Module '$module' not loaded" };
	}

	delete($self->{modules}->{$moduleKey});
	@{$self->{moduleList}} = grep { $_ ne $moduleKey } @{$self->{moduleList}};

	return { status => 1, code => -1, string => "Module '$module' unloaded" };
}

# Enables or activates a module
sub enableModule {
	my ($self, $module) = @_;
	my $moduleKey = lc($module);

	unless ($self->{modules}->{$moduleKey}) {
		return { status => 0, code => 0, string => "Module '$module' not loaded" };
	}

	if ($self->{modules}->{$moduleKey}->{enabled} == 1) {
		return { status => 0, code => 1, string => "Module '$module' already enabled" };
	}

	$self->{modules}->{$moduleKey}->{enabled} = 1;

	return { status => 1, code => -1, string => "Module '$module' enabled" };
}

# Disables a module. Note that it stays active in memory, including any
# variables that might have changed. Disabled modules can be reenabled again,
# using the same state (including variables) prior to disabling if other modules
# didn't mess with it.
sub disableModule {
	my ($self, $module) = @_;
	my $moduleKey = lc($module);

	unless ($self->{modules}->{$moduleKey}) {
		return { status => 0, code => 0, string => "Module '$module' not loaded" };
	}

	if ($self->{modules}->{$moduleKey}->{enabled} == 0) {
		return { status => 0, code => 1, string => "Module '$module' already disabled" };
	}

	$self->{modules}->{$moduleKey}->{enabled} = 0;

	return { status => 1, code => -1, string => "Module '$module' disabled" };
}

# Registers code to be executed on certain IRC events of type $type. Valid types
# are: connected, said, emoted, noticed, chanjoin, chanpart, topic, nick_change,
# kicked, userquit and invited. See CPAN pages for Bot::BasicBot for parameter
# details and general usage. Event invited isn't in Bot::BasicBot and is built
# in here. Code hooks are usually registered through module's init() function,
# but can theoretically be called on the fly from wherever inside a module.
sub registerHook {
	my ($self, $module, $type, $function) = @_;

	push(@{$self->{modules}->{$module}->{hooks}->{$type}}, $function);

	return { status => 1, code => -1, string => "Hook with type '$type' for module '$module' registered" };
}

# Unregisters a code hook from a module. $function must contain the exact same
# code used to register to unregister it.
sub unregisterHook {
	my ($self, $module, $type, $function) = @_;

	unless (grep($function, @{$self->{modules}->{$module}->{hooks}->{$type}})) {
		return { status => 0, code => 0, string => "Hook with type '$type' for module '$module' does not exist" };
	}

	@{$self->{modules}->{$module}->{hooks}->{$type}} = grep { $_ != $function } @{$self->{modules}->{$module}->{hooks}->{$type}};

	return { status => 1, code => -1, string => "Hook with type '$type' for module '$module' unregistered" };
}

# Unregisters all hooks from a module
sub unregisterHooks {
	my ($self, $module, $type) = @_;

	$self->{modules}->{$module}->{hooks}->{$type} = ();

	return { status => 1, code => -1, string => "All hooks with type '$type' for module '$module' unregistered" };
}

# Returns an array of functions with registered hooks for a module
sub getHooks {
	my ($self, $module, $type) = @_;

	return @{$self->{modules}->{$module}->{hooks}->{$type}};
}

# todo
sub hookRegistered {
	my ($self, $module, $type) = @_;

	return @{$self->{modules}->{$module}->{hooks}->{$type}};
}

# Process hooks of type $type. Loops through every active (!) module and calls
# hooked function(s), if any. Function calls are done in an eval{} block to
# catch logic errors and unloads the module if it happens to find an error.
sub processHooks {
	my ($self, $type, $data) = @_;

	# For each module
	while (my ($module, $moduleHash) = each(%{$self->{modules}})) {
		next if ($moduleHash->{enabled} == 0);

		# For each hook of said type
		foreach (@{$moduleHash->{hooks}->{$type}}) {
			eval { $self->$_($data); };

			# Complain and unload module on error
			if ($@) {
				$self->say(
					who     => $data->{who},
					channel => $data->{channel},
					body    => "\x02Module '$module' encountered an error and will be unloaded:\x0F $@",
					address => $data->{address}
				);

				$self->unloadModule($module);
			}
		}
	}
}

# Returns whether module $module is loaded
sub moduleLoaded {
	my ($self, $module) = @_;
	return (exists($self->{modules}->{lc($module)}) ? 1 : 0);
}

# Returns whether module $module is both loaded and active
sub moduleActive {
	my ($self, $module) = @_;
	return (($self->moduleLoaded($module) && ($self->{modules}->{lc($module)}->{enabled} == 1)) ? 1 : 0);
}

# Returns a module
sub module {
	my ($self, $module) = @_;

	unless (moduleLoaded($module)) {
		return undef;
	}

	return $self->{modules}->{lc($module)}->{object};
}

# --- POE extensions ---

# Register irc_invite event to our handle_invite function
sub start_state {
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];
	my $ret = $self->SUPER::start_state($self, $kernel, $session);
	$kernel->state('irc_invite', $self, 'handle_invite');
	return $ret;
}

# Handle IRC INVITE commands through hooks
sub handle_invite {
	my ($self, $inviter, $channel, $key) = @_[OBJECT, ARG0, ARG1];
	$self->processHooks('invited', {inviter => $inviter, channel => $channel});
}

# Join IRC channel function
sub join_channel {
	my ($self, $channel, $key) = @_;
	$key = '' unless defined($key);
	$poe_kernel->post($self->{IRCNAME}, 'join', $channel, $key);
}

# Leave IRC channel function
sub leave_channel {
	my ($self, $channel, $part_msg) = @_;
	$part_msg ||= ('PinkieBot v' . $version);
	$poe_kernel->post($self->{IRCNAME}, 'part', $channel, $part_msg);
}

# --- PinkieBot::Module ---

# PinkieBot::Module should be the base of every module. Contains a reference to
# the bot and contains a handy function for registering hooks.

package PinkieBot::Module;

use warnings;
use strict;

# Reloading the same module file usually gives redefinition warnings. So disable
# them here.
no warnings 'redefine';

sub new {
	my ($class, $bot) = @_;

	my $self = {bot => $bot};
	bless($self, $class);

	$self->init($bot);

	return $self;
}

sub registerHook {
	my ($self, $type, $code) = @_;

	my $module = ref($self);
	$module =~ s/PinkieBot::Module::(.*)/$1/;
	$module = lc($module);

	$self->{bot}->registerHook($module, $type, $code);
}

sub init { undef }
