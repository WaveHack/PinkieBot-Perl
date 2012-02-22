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

package PinkieBot::Module::Wikipedia;
use base 'PinkieBot::Module';

use WWW::Wikipedia;
use HTML::Strip;

my $wiki;
my $hs;

sub init {
	my ($self, $bot, $message, $args) = @_;

	$wiki = WWW::Wikipedia->new();
	$hs = HTML::Strip->new();

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!w(?:iki)? (.+)/);
	my $searchTerm = $1;

	my $entry = $wiki->search($searchTerm);

	unless (defined($entry)) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($message->{who} . ': Sorry, I can\'t find anything for \'' . $searchTerm . '\' on Wikipedia.org.'),
			address => $message->{address}
		);

		return;
	}

	# Return if there's a disambiguation page or page doesn't exist
	return unless ($entry->text());

	# Build URL for the term
	my $url = $searchTerm;
	$url =~ s/ /_/g;
	$url = ('http://en.wikipedia.org/wiki/' . $url);

	my $text = $entry->text();
	$text =~ s/(\{\{.+?\}\})//gs; # Remove wiki stuff
	$text =~ s/\[\[(.+?)\]\]/$1/gs; # Remove internal Wiki links
	$text =~ s/[\r\n]/ /gs; # Remove newlines
	$text =~ s/( {2,})/ /gs; # Limit spaces to singles

	# Strip HTML
	$text = $hs->parse($text);
	$hs->eof;

	# Limit to 293 characters to prevent spam
	$text = ((length($text) > 296) ? (substr($text, 0, 293) . '...') : $text);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($message->{who} . ': Wikipedia entry for \'' . $searchTerm . '\' (' . $url . '):'),
		address => $message->{address}
	);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => $text,
		address => $message->{address}
	);
}

1;
