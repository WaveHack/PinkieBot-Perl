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

package PinkieBot::Module::Auth;
use base 'PinkieBot::Module';

my %authenticatedUsers = ();

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Create needed tables if needed
	$self->createTableIfNotExists('auth', $message);

	# Register hooks
	$self->registerHook('said', \&handleSaidLogin);
	$self->registerHook('said', \&handleSaidLogout);
	$self->registerHook('said', \&handleSaidLogoutAll);
	$self->registerHook('said', \&handleSaidWhoami);
	$self->registerHook('said', \&handleSaidListUsers);
	$self->registerHook('said', \&handleSaidListUsernames);
	$self->registerHook('said', \&handleSaidAddUser);
	$self->registerHook('said', \&handleSaidDeleteUser);
	$self->registerHook('said', \&handleSaidChangeLevel);
}

sub handleSaidLogin {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^login ([^ ]+) (.*)/);
	return unless ($message->{channel} eq 'msg');

	my $username = $1;
	my $password = $2;

	# Check if already logged in
	if (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are already logged in from $message->{raw_nick}.",
			address => $message->{address}
		);

		return;
	}

	# Get level
	my $sth = $bot->{db}->prepare('SELECT level FROM auth WHERE username = ? AND password = SHA1(?) LIMIT 1;');
	$sth->execute($username, $password);
	my $level = $sth->fetchrow_array();

	# Invalid username/password
	unless (defined($level)) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "Invalid username/password combination.",
			address => $message->{address}
		);

		return;
	}

	# Store login
	$authenticatedUsers{$message->{raw_nick}} = $level;

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "You are now logged in from $message->{raw_nick} with authorization level $level.",
		address => $message->{address}
	);
}

sub handleSaidLogout {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^logout$/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Logout
	delete($authenticatedUsers{$message->{raw_nick}});

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "You have been logged out from '$message->{raw_nick}'.",
		address => $message->{address}
	);
}

sub handleSaidLogoutAll {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^logout all$/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Logout everypony
	for (keys %authenticatedUsers) {
		delete($href{$_});
	}

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "Everyone (including you) has been logged out. You have been logged out from '$message->{raw_nick}'.",
		address => $message->{address}
	);
}

sub handleSaidWhoami {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^whoami$/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Logged in
	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "You are logged in as '$message->{raw_nick}' with autorization level $authenticatedUsers{$message->{raw_nick}}.",
		address => $message->{address}
	);
}

sub handleSaidListUsers {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^list users$/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Check if authorized (level 9+)
	unless (authorizationLevel($message->{raw_nick}) >= 9) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ('You are not authorized to use this command. Have authentication level ' . authorizationLevel($message->{raw_nick}) . ', need at least 9.'),
			address => $message->{address}
		);

		return;
	}

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ('Logged in users: ' . join(', ', sort(keys(%authenticatedUsers))) . '.'),
		address => $message->{address}
	);
}

sub handleSaidListUsernames {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^list usernames$/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Check if authorized (level 9+)
	unless (authorizationLevel($message->{raw_nick}) >= 9) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ('You are not authorized to use this command. Have authentication level ' . authorizationLevel($message->{raw_nick}) . ', need at least 9.'),
			address => $message->{address}
		);

		return;
	}

	my (@usernames, $username, $level);
	my $sth = $bot->{db}->prepare('SELECT username, level FROM auth ORDER BY username;');

	$sth->execute();
	$sth->bind_columns(undef, \$username, \$level);

	while ($sth->fetch()) {
		push(@usernames, "$username ($level)");
	}

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ('Registered usernames: ' . join(', ', @usernames) . '.'),
		address => $message->{address}
	);
}

sub handleSaidAddUser {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^adduser ([^ ]+) ([^ ]+)(?: ([0-9]+))?/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Check if authorized (level 9+)
	unless (authorizationLevel($message->{raw_nick}) >= 9) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ('You are not authorized to use this command. Have authentication level ' . authorizationLevel($message->{raw_nick}) . ', need at least 9.'),
			address => $message->{address}
		);

		return;
	}

	$username = $1;
	$password = $2;
	$level = $3;

	unless (defined($level)) {
		$level = 0;
	}

	# Insert user
	my $sth = $bot->{db}->prepare('INSERT INTO auth (username, password, level) VALUES (?, SHA1(?), ?);');
	$sth->execute($username, $password, $level);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "User '$username' has been added with password '$password' and authorization level '$level'.",
		address => $message->{address}
	);
}

sub handleSaidDeleteUser {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^deluser (.*)/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Check if authorized (level 9+)
	unless (authorizationLevel($message->{raw_nick}) >= 9) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ('You are not authorized to use this command. Have authentication level ' . authorizationLevel($message->{raw_nick}) . ', need at least 9.'),
			address => $message->{address}
		);

		return;
	}

	$username = $1;

	my $sth = $bot->{db}->prepare('SELECT 1 FROM auth WHERE username = ? LIMIT 1;');
	$sth->execute($username);

	unless ($sth->rows == 1) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "User '$username' does not exist.",
			address => $message->{address}
		);

		return;
	}

	$sth = $bot->{db}->prepare('DELETE FROM auth WHERE username = ?;');
	$sth->execute($username);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "User '$username' deleted.",
		address => $message->{address}
	);
}

sub handleSaidChangeLevel {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^changelevel ([^ ]+) ([0-9]+)/);
	return unless ($message->{channel} eq 'msg');

	# Check if not logged in
	unless (isLoggedIn($message->{raw_nick})) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "You are not logged in.",
			address => $message->{address}
		);

		return;
	}

	# Check if authorized (level 9)
	unless (authorizationLevel($message->{raw_nick}) >= 9) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ('You are not authorized to use this command. Have authentication level ' . authorizationLevel($message->{raw_nick}) . ', need at least 9.'),
			address => $message->{address}
		);

		return;
	}

	$username = $1;
	$level = $2;

	my $sth = $bot->{db}->prepare('SELECT 1 FROM auth WHERE username = ? LIMIT 1;');
	$sth->execute($username);

	unless ($sth->rows == 1) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "User '$username' does not exist.",
			address => $message->{address}
		);

		return;
	}

	$sth = $bot->{db}->prepare('UPDATE auth SET level = ? WHERE username = ?;');
	$sth->execute($level, $username);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => "Level for '$username' is now $level.",
		address => $message->{address}
	);
}

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

1;
