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

package PinkieBot::Module::Social;
use base 'PinkieBot::Module';

use Switch;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidGreet);
	$self->registerHook('emoted', \&handleEmoteFriendly);
}

# Responds to simple greetings
sub handleSaidGreet {
	my ($bot, $message) = @_;

	my $botName = $bot->pocoirc->nick_name;
	return unless ($message->{body} =~ /^(.+) (?:$botName)$/i);

	my $response;
	switch (lc($1)) {
		case 'hi'    { $response = 'Hi $1.'; }
		case 'hello' { $response = 'Hello to you too, $1!'; }
		case 'herro' { $response = 'Herro herro, $1!'; }
		case 'hey'   { $response = '$1! Heya!'; }
		case 'lo'    { $response = 'Lo $1.'; }
		case 'yo'    { $response = 'Yo yo yo $1!'; }
		case 'sup'   { $response = 'Sup dawg?'; }
		case 'wazaa' { $response = 'Waaazzaaaaaaa!'; }
		case 'hai2u' { $response = 'Hai2u2 $1.'; }
		case 'ohai'  { $response = 'Ohey Johnny- eh I mean $1, what\'s up?'; }
		else         { return; }
	}

	# Replace $1 with the name of the person invoking it
	$response =~ s/\$1/$message->{who}/;

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $response,
		address => $message->{address}
	);
}

sub handleEmoteFriendly {
	my ($bot, $message) = @_;

	my $botName = $bot->pocoirc->nick_name;
	return unless ($message->{body} =~ /^(.+) (?:$botName)$/i);

	my $response;
	switch (lc($1)) {
		case 'hugs'        { $response = 'hugs $1 back'; }
		case 'licks'       { $response = 'is paralyzed'; }
		case 'soothes'     { $response = 'cheers up'; }
		case 'comforts'    { $response = 'cheers up'; }
		case 'pats'        { $response = 'purrs'; }
		case 'gently pats' { $response = 'purrs'; }
		case 'praises'     { $response = 'is proud'; }
		case 'cheers at'   { $response = 'is proud'; }
		case 'kisses'      { $response = 'blushes'; }
		case 'blushes at'  { $response = 'blushes'; }
		case 'brohoofs'    { $response = 'brohoofs $1 back'; }
		else               { return; }
	}

	# Replace $1 with the name of the person invoking it
	$response =~ s/\$1/$message->{who}/;

	$bot->emote(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $response,
		address => $message->{address}
	);
}

1;
