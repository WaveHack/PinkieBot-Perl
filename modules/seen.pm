package PinkieBot::Module::Seen;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

use Switch;

my %dbsth;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Check if module Log is loaded
	if (!$bot->moduleLoaded('log')) {
		# If $message is defined, we're calling it from IRC. Else it's from
		# autoloading. Don't try to say() command there since we're obviously
		# not connected to IRC yet.
		if (defined($message)) {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "\x02Warning\x0F: Module 'Log' is not loaded or disabled and this module sort of depends on it. Type !load Log to enable module 'Log' or suffer the consequences.",
				address => $message->{address}
			);

		# Autoload, print to CLI only
		} else {
			print "\nWarning: Module 'Log' is not loaded or disabled and this module sort of depends\n"
			    , "on it. Type !load Log to enable module 'Log' or suffer the consequences.\n";
		}
	}

	# Create needed tables if needed
	$self->createTableIfNotExists('activity', $message);

	# Prepared statements
	$dbsth{seen} = $self->{bot}->{db}->prepare('SELECT type, timestamp, channel, body FROM activity WHERE lower(who) = lower(?) ORDER BY timestamp DESC LIMIT 1;');

	# Register hooks
	$self->registerHook('said', \&handleSaidSeen);
}

# !seen person
# Outputs when the person was last seen on IRC, regardless of channel
sub handleSaidSeen {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!seen (.+)$/);

	my $who = $1;
	my ($type, $timestamp, $channel, $body);

	$dbsth{seen}->execute($1);
	$dbsth{seen}->bind_columns(\$type, \$timestamp, \$channel, \$body);
	$dbsth{seen}->fetch;

	unless (defined($type) || (defined($channel) && ($channel eq 'msg'))) {
		$bot->say(
			who     => $message->{who},
			channel => $message->{channel},
			body    => "Sorry, I have not seen $who before",
			address => $message->{address}
		);
		return;
	}

	# Relative date
	$timestamp = secsToString(time() - $timestamp);

	switch ($type) {
		case 'said' {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "$who was last seen in $channel $timestamp saying \"$body\".",
				address => $message->{address}
			);
		}
		case 'emote' {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "$who was last seen in $channel $timestamp emoting: \"* $who $body\".",
				address => $message->{address}
			);
		}
		case 'chanjoin' {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "$who was last seen joining channel $channel $timestamp.",
				address => $message->{address}
			);
		}
		case 'chanpart' {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "$who was last seen parting channel $channel $timestamp.",
				address => $message->{address}
			);
		}
		case 'userquit' {
			$bot->say(
				who     => $message->{who},
				channel => $message->{channel},
				body    => "$who was last seen $timestamp quiting IRC with the message: \"$body\".",
				address => $message->{address}
			);
		}
		else {
			# Seen in a channel
			if ($channel ne '') {
				$bot->say(
					who     => $message->{who},
					channel => $message->{channel},
					body    => "$who was last seen in $channel $timestamp.",
					address => $message->{address}
				);
			# Seen, but not sure where
			} else {
				$bot->say(
					who     => $message->{who},
					channel => $message->{channel},
					body    => "$who was last seen $timestamp, although not sure where.",
					address => $message->{address}
				);
			}
		}
	}
}

sub secsToString {
	my $secs = shift;
	my $string = "";

	$string .= sprintf("%dd ", (($secs / 86400)     )) if ($secs >= 86400);
	$string .= sprintf("%dh ", (($secs /  3600) % 24)) if ($secs >=  3600);
	$string .= sprintf("%dm ", (($secs /    60) % 60)) if ($secs >=    60);
	$string .= sprintf("%ds ", (($secs        ) % 60)) if ($secs         );
	$string .= "ago";

	return $string;
}

1;
