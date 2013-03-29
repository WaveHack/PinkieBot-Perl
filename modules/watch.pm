package PinkieBot::Module::Watch;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

my %watchlist;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidWatch);
	$self->registerHook('said', \&handleSaidUnwatch);
#	$self->registerHook('said', \&handleSaidUnwatchAll);
#	$self->registerHook('said', \&handleSaidWatching);
	$self->registerHook('said', \&handleSaid);
	$self->registerHook('emote', \&handleEmote);
}

sub handleSaidWatch {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!watch (.+)/);

	my $watcher = $message->{who};
	my $watched = $1;

	unless (exists($watchlist{$watcher})) {
		@{$watchlist{$watcher}} = ();
	}

	unless ($watched =~ @{$watchlist{$watcher}}) {
		push(@{$watchlist{$watcher}}, lc($watched));

		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => ($watcher . ': Okay.'),
			address => $message->{address}
		);

		return;
	}

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ($watcher . ': Already watching ' . $watched . '.'),
		address => $message->{address}
	);
}

sub handleSaidUnwatch {
	my ($bot, $message) = @_;
}

sub handleSaid {
	my ($bot, $message) = @_;

	my $person = $message->{who};

	while (my ($watcher, @watchedlist) = each(%watchlist)) {
		foreach my $watched (@{$watchlist{$watcher}}) {
			if (lc($person) eq $watched) {
				$bot->say(
					who     => $message->{who},
					channel => $message->{channel},
					body    => ($watcher . ': ' . $message->{who} . ' is here.'),
					address => $message->{address}
				);

				@{$watchlist{$watcher}} = grep { $_ != $watched } @{$watchlist{$watcher}};
			}
		}
	}
}

sub handleEmote {
	my ($bot, $message) = @_;
}

1;
