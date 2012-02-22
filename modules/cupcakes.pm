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

package PinkieBot::Module::Cupcakes;
use base 'PinkieBot::Module';

my %randomAnswers = (
	'say' => [
		'Cupcaakkesss!',
		'Cupcakes! So sweet and tasty!',
		'Cupcakes! Don\'t be too hasty!',
		'Cupcakes, cupcakes, cupcaakess!',
		'Did anypony say cupcakes?',
		'Yay! Cupcakes!',
		'Wooo! Cupcakes!'
	],
	'emote' => [
		'throws a party for $1!',
		'giggles',
		'cheers',
		'cackles maniacally at $1',
		'glares at $1'
	]
);
my $randomAnswerCount = 0;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Get random answer count
	while (my ($key, @value) = each(%randomAnswers)) {
		$randomAnswerCount += scalar(@{$randomAnswers{$key}});
	}

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /cupcakes/i);

	my $randomIndex = int(rand($randomAnswerCount));
	my $i, $output, $type;

	$i = 0;
	LOOP: while (my ($key, @value) = each(%randomAnswers)) {
		foreach (@{$randomAnswers{$key}}) {
			if ($i == $randomIndex) {
				$output = $_;
				$type   = $key;
				last LOOP;
			}
			$i++;
		}
	}

	# Replace $1 with the name of the person invoking it
	$output =~ s/\$1/$message->{who}/;

	if ($type eq 'say') {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => $output,
			address => $message->{address}
		);
	} elsif ($type eq 'emote') {
		$bot->emote(
			who     => $message->{who},
			channel => $message->{channel},
			body    => $output,
			address => $message->{address}
		);
	}
}

1;
