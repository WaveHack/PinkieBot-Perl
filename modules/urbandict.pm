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

package PinkieBot::Module::Urbandict;
use base 'PinkieBot::Module';

use LWP::Simple;
use HTML::Strip;

my $hs;

sub init {
	my ($self, $bot, $message, $args) = @_;

	$hs = HTML::Strip->new();

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!ud (.+)/);

	my $term = $1;
	my $url = ('http://www.urbandictionary.com/define.php?term=' . $term);

	my $page = get($url) or return;

	$page =~ /<div class="definition">(.+?)<\/div>/;

	# Return if $term isn't defined (yet)
	return if ($1 eq $term);

	my $definition = $1;
	$definition =~ s/<br\/>/ /g; # Remove newlines
	$definition =~ s/( {2,})/ /; # Limit spaces to singles

	# Strip HTML
	$definition = $hs->parse($definition);
	$hs->eof;

	# Limit to 293 characters to prevent spam
	$definition = ((length($definition) > 296) ? (substr($definition, 0, 293) . '...') : $definition);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Definition for \'' . $term . '\' on Urban Dictionary:'),
		address => $message->{address}
	);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $definition,
		address => $message->{address}
	);
}

1;
