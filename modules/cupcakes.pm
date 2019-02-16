package PinkieBot::Module::Cupcakes;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

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
	my ($i, $output, $type);

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

	unless (defined($type)) {
		return;
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
