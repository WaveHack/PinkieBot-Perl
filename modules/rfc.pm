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

package PinkieBot::Module::Rfc;
use base 'PinkieBot::Module';

use LWP::Simple;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!rfc (\d+)$/);

	my $rfc = $1;
	my $url = ('http://tools.ietf.org/html/rfc' . $rfc);

	my $page = get($url) or return;

	$page =~ /<title>(.+?)<\/title>/;
	my $title = $1;

	$page =~ /<meta name="DC.Description.Abstract" content="(.+?)" \/>/;
	my $abstract = $1;
	$abstract =~ s/\\n/ /g; # Remove fake newlines
	$abstract =~ s/( {2,})/ /; # Limit spaces to singles

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . $title . ' (' . $url . ')'),
		address => $message->{address}
	);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $abstract,
		address => $message->{address}
	);
}

1;
