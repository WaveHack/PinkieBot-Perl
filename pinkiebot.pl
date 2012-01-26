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
use Switch;
use DBI;
use DateTime;
use DateTime::Util::Astro::Moon 'lunar_phase';
use URI::Title 'title';

use warnings;
use strict;

my $version = '1.2.3';
my $botinfo = ('PinkieBot v' . $version . ' by WaveHack. See https://bitbucket.org/WaveHack/pinkiebot/ for more info, command usage and source code.');

# --- Initialization ---

print "PinkieBot v" . $version . " started\n";

print "Loading config\n";

# Create configuration file if not exists
unless (-e 'pinkiebot.ini') {
	print "No configuration file found. Creating one with placeholder variables. Please\n"
	    . "modify pinkiebot.ini and restart the bot. Also make sure the database schema in\n"
	    . "pinkiebot.sql is imported in your MySQL database.\n";

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
	$cfg->SetParameterComment('irc', 'channels', 'Separate multiple channels with a space');
	$cfg->WriteConfig('pinkiebot.ini');
	exit;
}

my $cfg = Config::IniFiles->new(-file => 'pinkiebot.ini');

unless (
	$cfg->exists('mysql', 'host')     && ($cfg->val('mysql', 'host')     ne '') &&
	$cfg->exists('mysql', 'username') && ($cfg->val('mysql', 'username') ne '') &&
	$cfg->exists('mysql', 'password') &&
	$cfg->exists('mysql', 'database') && ($cfg->val('mysql', 'database') ne '') &&
	$cfg->exists('irc',   'nick')     && ($cfg->val('irc',   'nick')     ne '') &&
	$cfg->exists('irc',   'server')   && ($cfg->val('irc',   'server')   ne '') &&
	$cfg->exists('irc',   'channels') && ($cfg->val('irc',   'channels') ne '')
)  {
	print "Invalid configuration. Check that at least variables nick, server and channels\n"
	    . "in section [irc] and variables host, username, password and database in section\n"
	    . " [mysql] are present.\n";
	exit;
}

print "Connecting to database\n";
my $dbh = DBI->connect(sprintf('DBI:mysql:%s;host=%s', $cfg->val('mysql', 'database'), $cfg->val('mysql', 'host')), $cfg->val('mysql', 'username'), $cfg->val('mysql', 'password'));

print "Generating prepared statements\n";
my %dbsth = (
	'activity',          $dbh->prepare("INSERT INTO activity (type, timestamp, who, raw_nick, channel, body, address) VALUES (?, UNIX_TIMESTAMP(), ?, ?, ?, ?, ?);"),
	'karma_select',      $dbh->prepare("SELECT karma FROM karma WHERE name = ? LIMIT 1;"),
	'karma_insert',      $dbh->prepare("INSERT INTO karma (name, karma) VALUES (?, ?);"),
	'karma_update',      $dbh->prepare("UPDATE karma SET karma = ? WHERE name = ?;"),
	'seen',              $dbh->prepare("SELECT type, timestamp, channel, body FROM activity WHERE lower(who) = lower(?) ORDER BY timestamp DESC LIMIT 1;"),
	'searchquote',       $dbh->prepare("SELECT type, who, body FROM activity WHERE channel = ? AND body LIKE ? AND lower(who) != lower(?) AND BODY NOT LIKE \"!%\" ORDER BY timestamp DESC LIMIT 1"),
	'searchquotedouble', $dbh->prepare("SELECT type, who, body FROM activity WHERE channel = ? AND body LIKE ? AND body LIKE ? AND lower(who) != lower(?) AND BODY NOT LIKE \"!%\" ORDER BY timestamp DESC LIMIT 1")
);

my $bot;

# --- Overridden callback methods ---

sub connected {
	print "Connected\n";

	# NickServ auth
	if ($cfg->val('irc', 'nickpass') ne '') {
		print "Authenticating\n";
		$bot->say(
			channel => 'nickserv',
			body    => ('identify ' . $cfg->val('irc', 'nickpass'))
		);
	}

	print "Ready\n";
}

sub said {
	my ($self, $message) = @_;

	# Module hooks
	hookSaidKarma($self, $message);
	hookSaidPonify($self, $message);
	hookSaidSeen($self, $message);
	hookSaidQuoteReplace($self, $message);
	hookSaidQuoteSearch($self, $message);
	hookSaidQuoteSwitch($self, $message);
	hookSaidURLTitle($self, $message);
	hookSaidBotInfo($self, $message);
	hookSaidOatmeal($self, $message);
	hookSaidHavermout($self, $message);

	# Activity
	$dbsth{activity}->execute('said', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});

	return;
}

sub emoted {
	my ($self, $message) = @_;

	# Module hooks
	hookEmotePinkiePolice($self, $message);

	# Activity
	$dbsth{activity}->execute('emote', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});

	return;
}

sub noticed {
	my ($self, $message) = @_;

	# Ignore InfoServ, ChanServ and NickServ notices (boooriinng)
	return if (
		($message->{who} eq 'InfoServ')
		|| ($message->{who} eq 'ChanServ')
		|| ($message->{who} eq 'NickServ')
	);

	# Activity
	$dbsth{activity}->execute('notice', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});

	return;
}

sub chanjoin {
	my ($self, $message) = @_;

	# Activity
	$dbsth{activity}->execute('chanjoin', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});

	return;
}

sub chanpart {
	my ($self, $message) = @_;

	# Activity
	$dbsth{activity}->execute('chanpart', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});

	return;
}

sub topic {
	my ($self, $message) = @_;

	# Activity
	$dbsth{activity}->execute('topic', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{topic}, $message->{address});

	return;
}

sub nick_change {
	my ($self, $oldnick, $newnick) = @_;

	# Activity
	$dbsth{activity}->execute('nickchange', $oldnick, undef, undef, $newnick, undef);

	return;
}

sub kicked {
	my ($self, $message) = @_;

	# Activity
	$dbsth{activity}->execute('kicked', $message->{who}, $message->{kicked}, $message->{channel}, $message->{reason}, undef);

	return;
}

sub userquit {
	my ($self, $message) = @_;

	# Activity
	$dbsth{activity}->execute('userquit', $message->{who}, undef, undef, $message->{body}, undef);

	return;
}

sub help {
	return $botinfo;
}

# --- Module hooks ---

# Karma module
sub hookSaidKarma {
	my ($self, $message) = @_;

	my ($name, $operator, $karma);
	my $exists = 0;

	# Karma'ing the bot
	if (
		defined($message->{address}) &&
		(lc($message->{address}) eq lc($self->pocoirc->nick_name)) && (
			($message->{body} eq '-') ||
			($message->{body} eq '++')
		)
	) {
		$name = $message->{address};
		# Addressing the bot with minus signs removes the first minus sign from
		# the body, so check it manually here. ++ = ++, - = --. Yeah.
		$operator = (($message->{body} eq '++') ? '++' : '--');

	# Karma'ing anything else
	} elsif ($message->{body} =~ /^([^\s]+)\s*(\+\+|\-\-)$/) {
		$name = $1;
		$operator = $2;

	# No karma
	} else {
		return;
	}

	# In the past we had problems with long texts which ended in ++ or --, so
	# just limit it to 20 characters
	return unless (length($name) < 20);

	# If someone downreps the bot and we can kick him, kick him! >:)
	if ((lc($name) eq lc($self->pocoirc->nick_name)) && ($operator eq '--') && canKick($self, $message->{channel}, $message->{who})) {
		$self->kick($message->{channel}, $message->{who}, 'Oh no you don\'t!');
		return;
	}

	# Check if karma record exists in db
	$dbsth{karma_select}->execute(lc($name));
	$dbsth{karma_select}->bind_columns(\$karma);
	$dbsth{karma_select}->fetch;

	$exists = 1 if defined($karma);
	$karma = 0 unless ($exists == 1);

	# Do fancy math
	eval("\$karma$operator;");

	# Database update/insert
	$exists
		? $dbsth{karma_update}->execute($karma, lc($name))
		: $dbsth{karma_insert}->execute(lc($name), $karma);

	# Check if the bot is being addressed by the karma
	if (lc($name) eq lc($self->pocoirc->nick_name)) {
		# Can't kick the user (else we would have done 20 lines above), so just
		# actually rep now and add a ':('.
		if ($operator eq '--') {
			$self->say(channel => $message->{channel}, body => "Karma for $name is now $karma. :(");
		# Bot++ <3
		} else {
			$self->say(channel => $message->{channel}, body => "Karma for $name is now $karma (thanks! <3).");
		}
	} else {
		$self->say(channel => $message->{channel}, body => "Karma for $name is now $karma.");
	}
}

# Ponify module
# Slaps and corrects any neighsayer who misspells the words 'anypony',
# 'everypony' and 'nopony'
sub hookSaidPonify {
	my ($self, $message) = @_;

	if ($message->{body} =~ /(anybody|anyone|any one)/i) {
		$self->emote(channel => $message->{channel}, body => ('slaps ' . $message->{who}));
		$self->say(channel => $message->{channel}, body => "It's anypony, not $1!");
		return;
	}
	if ($message->{body} =~ /(everybody|everyone|every one)/i) {
		$self->emote(channel => $message->{channel}, body => ('slaps ' . $message->{who}));
		$self->say(channel => $message->{channel}, body => "It's everypony, not $1!");
		return;
	}
	if ($message->{body} =~ /(nobody|noone|no one)/i) {
		$self->emote(channel => $message->{channel}, body => ('slaps ' . $message->{who}));
		$self->say(channel => $message->{channel}, body => "It's nopony, not $1!");
		return;
	}
	if ($message->{body} =~ /(somebody|someone|some one)/i) {
		$self->emote(channel => $message->{channel}, body => ('slaps ' . $message->{who}));
		$self->say(channel => $message->{channel}, body => "It's somepony, not $1!");
		return;
	}
}

# Seen module
sub hookSaidSeen {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /^!seen (.+)$/);

	my $who = $1;
	my ($type, $timestamp, $channel, $body);

	$dbsth{seen}->execute($1);
	$dbsth{seen}->bind_columns(\$type, \$timestamp, \$channel, \$body);
	$dbsth{seen}->fetch;

	unless (defined($type) || (defined($channel) && ($channel eq 'msg'))) {
		$self->say(channel => $message->{channel}, body => "Sorry, I have not seen $who before");
		return;
	}

	# Relative date
	$timestamp = secsToString(time() - $timestamp);

	switch ($type) {
		case 'said' {
			$self->say(channel => $message->{channel}, body => "$who was last seen in $channel $timestamp saying \"$body\".");
		}
		case 'emote' {
			$self->say(channel => $message->{channel}, body => "$who was last seen in $channel $timestamp emoting: \"* $who $body\".");
		}
		case 'chanjoin' {
			$self->say(channel => $message->{channel}, body => "$who was last seen joining channel $channel $timestamp.");
		}
		case 'chanpart' {
			$self->say(channel => $message->{channel}, body => "$who was last seen parting channel $channel $timestamp.");
		}
		case 'userquit' {
			$self->say(channel => $message->{channel}, body => "$who was last seen $timestamp quiting IRC with the message: \"$body\".");
		}
		else {
			# Seen in a channel
			if ($channel ne '') {
				$self->say(channel => $message->{channel}, body => "$who was last seen in $channel $timestamp.");
			# Seen, but not sure where
			} else {
				$self->say(channel => $message->{channel}, body => "$who was last seen $timestamp, although not sure where.");
			}
		}
	}
}

# Quote Replace module
sub hookSaidQuoteReplace {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /^!(ss?) (?:\"([^"]+)\"|(.+?)) (?:\"([^"]+)\"|(.+))$/);

	my $cmd = $1;
	my $search = $2 || $3;
	my $replace = $4 || $5;
	my ($type, $who, $body);

	# Search latest line, not by our bot and not starting with !s
	$dbsth{searchquote}->execute($message->{channel}, "%$search%", $self->pocoirc->nick_name);
	$dbsth{searchquote}->bind_columns(\$type, \$who, \$body);
	$dbsth{searchquote}->fetch;

	return unless defined($who);

	# !ss is replace all occurences (regex global), !s is replace first
	# occurence. Also escape all meta characters.
	($cmd eq 'ss')
		? $body =~ s/\Q$search/$replace\E/ig
		: $body =~ s/\Q$search/$replace\E/i;

	switch ($type) {
		case 'said' {
			$self->say(channel => $message->{channel}, body => "<$who> $body");
		}
		case 'emote' {
			$self->say(channel => $message->{channel}, body => "* $who $body");
		}
	}
}

# Quote Search module
sub hookSaidQuoteSearch {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /^!q (.+)$/);

	my $search = $1;
	my ($type, $who, $body);

	# Search latest line, not by our bot and not starting with !
	$dbsth{searchquote}->execute($message->{channel}, "%$search%", $self->pocoirc->nick_name);
	$dbsth{searchquote}->bind_columns(\$type, \$who, \$body);
	$dbsth{searchquote}->fetch;

	return unless defined($who);

	switch ($type) {
		case 'said' {
			$self->say(channel => $message->{channel}, body => "<$who> $body");
		}
		case 'emote' {
			$self->say(channel => $message->{channel}, body => "* $who $body");
		}
	}
}

# Quote Switch
sub hookSaidQuoteSwitch {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /^!sd (?:\"([^"]+)\"|(.+?)) (?:\"([^"]+)\"|(.+))$/);

	my $word1 = $1 || $2;
	my $word2 = $3 || $4;
	my ($type, $who, $body);

	# Search latest line, not by our bot and not starting with !
	$dbsth{searchquotedouble}->execute($message->{channel}, "%$word1%", "%$word2%", $self->pocoirc->nick_name);
	$dbsth{searchquotedouble}->bind_columns(\$type, \$who, \$body);
	$dbsth{searchquotedouble}->fetch;

	return unless defined($who);

	$body =~ s/\Q$word1\E/\x1A/ig;
	$body =~ s/\Q$word2/$word1\E/ig;
	$body =~ s/\x1A/\Q$word2\E/ig;
	$body =~ s/\\(.)/$1/g;

	switch ($type) {
		case 'said' {
			$self->say(channel => $message->{channel}, body => "<$who> $body");
		}
		case 'emote' {
			$self->say(channel => $message->{channel}, body => "* $who $body");
		}
	}
}

# URL title module
# Prints the title when someone pastes an URL
sub hookSaidURLTitle {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /((?:https?:\/\/|www\.)[-~=\\\/a-zA-Z0-9\.:_\?&%,#\+]+)/);
	return if ($1 eq '');

	my $title = title($1);

	$self->say(channel => $message->{channel}, body => "[ $title ]");
}

# Listens to !pinkiebot and prints info about the bot
sub hookSaidBotInfo {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /^!pinkiebot$/);

	$self->say(channel => $message->{channel}, body => $botinfo);
}

# Oatmeal? Are you crazy?!?
sub hookSaidOatmeal {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /oatmeal/i);

	$self->say(channel => $message->{channel}, body => ($message->{who} . ": Oatmeal? Are you crazy?!?"));
}

# Dutch Oatmeal module, thanks to Quantum_bit for the idea :')
sub hookSaidHavermout {
	my ($self, $message) = @_;

	return unless ($message->{body} =~ /havermout/i);

	$self->say(channel => $message->{channel}, body => ($message->{who} . ": Havermout? Ben je gek geworden?!?"));
}

# Pinkie Police module
# Upon noticing a hostile action, kick the user from the channel if one or
# more of the following conditions are true:
# 1) Hostile action against the bot,
# 2) The current hour is uneven,
# 3) It's friday,
# 4) It's a full moon.
# Why? Because I can, and because it's awesome.
sub hookEmotePinkiePolice {
	my ($self, $message) = @_;

	# Listen for hostile action
	return unless (
		($message->{body} =~ /^(slaps|hits|punches|stabs|kicks|prods|tazes|rapes) (.+)/) &&
		canKick($self, $message->{channel}, $message->{who})
	);

	# Always kick people who slap the bot
	if ($2 eq $self->pocoirc->nick_name) {
		$self->kick($message->{channel}, $message->{who}, 'Now why would you do that?');
		return;
	}

	my @timedata = localtime(time());

	# Check full moon. Perfect full moon is 180. Kick between 175-185.
	my $lunar_phase = int(lunar_phase(DateTime->now));
	if (($lunar_phase >= 175) && ($lunar_phase <= 185)) {
		$self->kick($message->{channel}, $message->{who}, 'Hostile actions are not permitted during full moons.');
		return;
	}

	# Check friday
	if ($timedata[6] == 5) {
		$self->kick($message->{channel}, $message->{who}, 'Hostile actions are not permitted on fridays.');
		return;
	}

	# Check uneven hour
	if ($timedata[2] % 2 == 1) {
		$self->kick($message->{channel}, $message->{who}, 'Hostile actions are not permitted during uneven hours.');
		return;
	}
}

# --- Helper functions ---

sub secsToString {
	my $secs = shift;
	my $string = "";

	$string .= sprintf("%dd ", (($secs / 86400)     )) if ($secs >= 86400);
	$string .= sprintf("%dh ", (($secs /  3600) % 24)) if ($secs >=  3600);
	$string .= sprintf("%dm ", (($secs /    60) % 60)) if ($secs >=    60);
	$string .= sprintf("%ds ", (($secs        ) % 60)) if ($secs         );
	$string .= "ago";

	return $string;
}

sub canKick {
	my ($bot, $channel, $who) = @_;

	# Check if we have op or halfop. If we're halfop, check if the user isn't op
	# since we can't kick him/her then.
	return (
		$bot->pocoirc->is_channel_operator($channel, $bot->pocoirc->nick_name) || (
			$bot->pocoirc->is_channel_halfop($channel, $bot->pocoirc->nick_name) &&
			!$bot->pocoirc->is_channel_operator($channel, $who)
		)
	);
}

# --- Create and start bot ---

$bot = PinkieBot->new(
	server   => $cfg->val('irc', 'server'),
	port     => $cfg->val('irc', 'port', '6667'),
	channels => [split(' ', $cfg->val('irc', 'channels'))],
	nick     => $cfg->val('irc', 'nick'),
	name     => ('PinkieBot v' . $version)
);

print "Starting bot\n";

$bot->run();
