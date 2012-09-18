package PinkieBot::Module::Auth;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

my %authenticatedUsers = ();

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Create needed tables if needed
	$self->createTableIfNotExists('auth', $message);

	# Register hooks
	$self->registerHook('said', \&handleSaidLogin);
	$self->registerHook('said', \&handleSaidLogout);
#	$self->registerHook('said', \&handleSaidLogoutAll);
	$self->registerHook('said', \&handleSaidWhoami);
	$self->registerHook('said', \&handleSaidListUsers);
	$self->registerHook('said', \&handleSaidListUsernames);
	$self->registerHook('said', \&handleSaidAddUser);
	$self->registerHook('said', \&handleSaidDeleteUser);
	$self->registerHook('said', \&handleSaidChangeLevel);
}

sub handleSaidLogin {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^login ([^ ]+) (.*)/));

	# Check if already logged in
	if (isLoggedIn($message->{raw_nick})) {
		$bot->reply("You are already logged in from '$message->{raw_nick}'.", $message);
		return;
	}

	my $username = $1;
	my $password = $2;

	# Check if user exists and get authorization level
	my $sth = $bot->{db}->prepare('SELECT level FROM auth WHERE username = ? AND password = SHA1(?) LIMIT 1;');
	$sth->execute($username, $password);
	my $level = $sth->fetchrow_array();

	# Invalid username/password
	unless (defined($level)) {
		$bot->reply("Invalid username/password combination.", $message);
		return;
	}

	# Store login
	$authenticatedUsers{$message->{raw_nick}} = $level;

	$bot->reply("You are now logged in from '$message->{raw_nick}' with authorization level $level.", $message);
}

sub handleSaidLogout {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^logout$/));
	return unless (checkAuthorization($bot, $message, 0));

	# Logout
	delete($authenticatedUsers{$message->{raw_nick}});

	$bot->reply("You have been logged out from '$message->{raw_nick}'.", $message);
}

sub handleSaidLogoutAll {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^logout all$/));
	return unless (checkAuthorization($bot, $message, 8));

	# Logout everypony
	# todo: fix
#	for (keys %authenticatedUsers) {
#		delete($href{$_});
#	}

#	$bot->reply("", $message);
}

sub handleSaidWhoami {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^whoami\??$/));
	return unless (checkAuthorization($bot, $message, 0));

	$bot->reply("You are logged in as '$message->{raw_nick}' with autorization level $authenticatedUsers{$message->{raw_nick}}.", $message);
}

sub handleSaidListUsers {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^list users$/));
	return unless (checkAuthorization($bot, $message, 8));

	$bot->reply(("Logged in users: " . join(', ', sort(keys(%authenticatedUsers))) . '.'), $message);
}

sub handleSaidListUsernames {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^list usernames$/));
	return unless (checkAuthorization($bot, $message, 8));

	my (@usernames, $username, $level);
	my $sth = $bot->{db}->prepare('SELECT username, level FROM auth ORDER BY username;');

	$sth->execute();
	$sth->bind_columns(undef, \$username, \$level);

	while ($sth->fetch()) {
		push(@usernames, "$username ($level)");
	}

	$bot->reply(("Registered usernames: " . join(',', @usernames) . '.'), $message);
}

sub handleSaidAddUser {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^adduser ([^ ]+) ([^ ]+)(?: ([0-9]+))?/));
	return unless (checkAuthorization($bot, $message, 8));

	my $username = $1;
	my $password = $2;
	my $level = $3;

	unless (defined($level)) {
		$level = 0;
	}

	# todo: Check if username already exists

	# Insert user
	my $sth = $bot->{db}->prepare('INSERT INTO auth (username, password, level) VALUES (?, SHA1(?), ?);');
	$sth->execute($username, $password, $level);

	$bot->reply("User '$username' has been added with password '$password' and authorization level '$level'.", $message);
}

sub handleSaidDeleteUser {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^deluser (.*)/));
	return unless (checkAuthorization($bot, $message, 8));

	my $username = $1;

	my $sth = $bot->{db}->prepare('SELECT 1 FROM auth WHERE username = ? LIMIT 1;');
	$sth->execute($username);

	unless ($sth->rows == 1) {
		$bot->reply("User '$username' doesn't exist.", $message);
		return;
	}

	$sth = $bot->{db}->prepare('DELETE FROM auth WHERE username = ?;');
	$sth->execute($username);

	$bot->reply("User '$username' deleted.", $message);
}

sub handleSaidChangeLevel {
	my ($bot, $message) = @_;

	return unless ($bot->addressedMsg($message) && ($message->{body} =~ /^changelevel ([^ ]+) ([0-9]+)/));
	return unless (checkAuthorization($bot, $message, 8));

	my $username = $1;
	my $level = $2;

	my $sth = $bot->{db}->prepare('SELECT 1 FROM auth WHERE username = ? LIMIT 1;');
	$sth->execute($username);

	unless ($sth->rows == 1) {
		$bot->reply("User '$username' doesn't exist.", $message);
		return;
	}

	my $authorizationLevel = authorizationLevel($message->{raw_nick});

	# Can only change level to equal or lower than current level
	if ($level > $authorizationLevel) {
		$bot->reply("Can only change target level to level $authorizationLevel or lower.", $message);
		return;
	}

	$sth = $bot->{db}->prepare('UPDATE auth SET level = ? WHERE username = ?;');
	$sth->execute($level, $username);

	$bot->reply("Level for '$username' is now $level.", $message);
}

# Helper functions

sub authorizationLevel {
	my ($self, $raw_nick) = @_;
	$raw_nick = $self unless (defined($raw_nick));

	unless (isLoggedIn($raw_nick)) {
		return -1;
	}

	return $authenticatedUsers{$raw_nick};
}

sub isLoggedIn {
	my ($self, $raw_nick) = @_;
	$raw_nick = $self unless (defined($raw_nick));

	return (exists($authenticatedUsers{$raw_nick}) ? 1 : 0);
}

# Global functions

sub checkAuthorization {
	my ($module, $bot, $message, $level) = @_;

	# When loading from a module, we have $module. If loading from here, we
	# don't have $module, so shift everything one place to the right.
	unless (defined($level)) {
		$level   = $message;
		$message = $bot;
		$bot     = $module;
	}

	my $raw_nick;
	if (defined($message->{raw_nick})) {
		$raw_nick = $message->{raw_nick};
	} elsif (defined($message->{inviter})) {
		$raw_nick = $message->{inviter};
	}

	unless (isLoggedIn($raw_nick)) {
		$bot->reply("You are not logged in.", $message);
		return 0;
	}

	my $authorizationLevel = authorizationLevel($raw_nick);

	unless ($authorizationLevel >= $level) {
		$bot->reply("You are not authorized to perform that command. (Have level $authorizationLevel, need level $level).", $message);
		return 0;
	}

	return 1;
}

1;
