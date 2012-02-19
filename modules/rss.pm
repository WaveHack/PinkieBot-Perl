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

package PinkieBot::Module::Rss;
use base 'PinkieBot::Module';

use POE;
use POE::Component::RSSAggregator;
use WWW::Shorten::Bitly;

sub connected {
	my $bot = shift;

	POE::Session->create(
		inline_states => (
			_start      => \&handleRSSSession,
			handle_feed => \&handleRSSFeed
		),
		args => [$bot]
	);
}

sub handleRSSSession {
	my ($kernel, $heap, $session, $bot) = @_[KERNEL, HEAP, SESSION, ARG0];

	$heap->{bot} = $bot;
	$heap->{rssagg} = POE::Component::RSSAggregator->new(
		alias    => 'rssagg',
		callback => $session->postback('handle_feed')
	);

	foreach my $feed ($bot->{cfg}->val('rss', 'feed')) {
		my $offset = rindex($feed, ' ');

		my $name = substr($feed, 0, $offset);
		my $url  = substr($feed, $offset + 1);

		$kernel->post('rssagg', 'add_feed', {
			url                 => $url,
			name                => $name,
			delay               => $bot->{cfg}->val('rss', 'delay', '300'),
			init_headlines_seen => 1
		});
	}
}

sub handleRSSFeed {
	my ($kernel, $heap, $feed) = ($_[KERNEL], $_[HEAP], $_[ARG1]->[0]);

	my $bot = $heap->{bot};

	foreach my $headline ($feed->late_breaking_news) {
		my $url;

		# Use Bit.ly if we set username/apikey in config
		if (
			defined($bot->{cfg}->val('rss', 'bitly_username')) && (bot->{cfg}->val('rss', 'bitly_username') ne '') &&
			defined($bot->{cfg}->val('rss', 'bitly_apikey'))   && (bot->{cfg}->val('rss', 'bitly_apikey') ne '')
		) {
			$url = makeashorterlink($headline->url, $cfg->val('rss', 'bitly_username'), $cfg->val('rss', 'bitly_apikey'));
		} else {
			$url = $headline->url;
		}

		# Report to each channel
		foreach my $channel (split(' ', $cfg->val('rss', 'channels'))) {
			$bot->say(
				channel => $channel,
				body    => sprintf("[ \x02%s\x0F: %s - %s ]", $feed->name, $headline->headline, $url)
			);
		}
	}
}

1;