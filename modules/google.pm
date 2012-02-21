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

package PinkieBot::Module::Google;
use base 'PinkieBot::Module';

use Google::Search;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidWebSearch);
	$self->registerHook('said', \&handleSaidImageSearch);
}

sub handleSaidWebSearch {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!g(?:oogle)? (.+)/);

	my $search = Google::Search->Web(query => $1);
	my $result = $search->first;

	my $title = $result->title;
	$title =~ s/<b>(.+?)<\/b>/\x02$1\x0F/g;

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . $title . ' - ' . $result->uri),
		address => $message->{address}
	);
}

sub handleSaidImageSearch {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!(?:gi|gimage|googleimages?) (.+)/);

	my $search = Google::Search->Image(query => $1);
	my $result = $search->first;

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': ' . $result->uri),
		address => $message->{address}
	);
}

1;
