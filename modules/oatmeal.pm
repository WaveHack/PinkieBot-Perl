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

package PinkieBot::Module::Oatmeal;
use base 'PinkieBot::Module';

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidOatmeal);
	$self->registerHook('said', \&handleSaidHavermout);
}

sub handleSaidOatmeal {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /oatmeal/i);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Oatmeal? Are you crazy?!'),
		address => $message->{address}
	);
}

sub handleSaidHavermout {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /havermout/i);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Havermout? Ben je gek?!'),
		address => $message->{address}
	);
}

1;
