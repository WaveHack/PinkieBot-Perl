package PinkieBot::Module::Ignore;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

my @ignored;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Create needed tables if needed
	$self->createTableIfNotExists('ignore', $message);

	# Register hooks
	$self->registerHook('said', \&handleSaidIgnore);
	$self->registerHook('said', \&handleSaidUnignore);
	$self->registerHook('said', \&handleSaidListIgnored);

	# Fill @ignored from db
	@ignored = @{$bot->{db}->selectcol_arrayref('SELECT `host` FROM `ignore`;')};
}

sub handleSaidIgnore {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!ignore (.+)/);
	return if ($bot->moduleActive('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $host = $1;

	# Check if already ignored
	if (grep(/\Q$host\E/i, @ignored)) {
		$bot->reply("Already ignored '$host'.", $message);
		return;
	}

	# Add host to array
	push(@ignored, $host);

	# Add host to db
	$bot->{db}->do("INSERT IGNORE INTO `ignore` (`host`) VALUES ('$host');");

	$bot->reply("Ignored '$host'.", $message);
}

sub handleSaidUnignore {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!unignore (.+)/);
	return if ($bot->moduleActive('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $host = $1;

	# Check if not ignored
	unless (grep(/\Q$host\E/i, @ignored)) {
		$bot->reply("'$host' is not ignored. Try '!list ignored' for a full list.", $message);
		return;
	}

	# Remove host from array
	@ignored = grep { not $ignored[$_] =~ /\Q$host\E/i } @ignored;

	# Remove host from db
	$bot->{db}->do("DELETE IGNORE FROM `ignore` WHERE `host` = '$host';");

	$bot->reply("Unignored '$host'.", $message);
}

sub handleSaidListIgnored {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!(list )?ignored/);
	return if ($bot->moduleActive('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $ignoredlist = join("', '", @ignored);
	if ($ignoredlist eq '') {
		$ignoredlist = "Nobody";
	} else {
		$ignoredlist = "'$ignoredlist'";
	}

	$bot->reply("Currently ignoring: $ignoredlist.", $message);
}

sub ignoring {
	my ($module, $bot, $message) = @_;

	unless (defined($message->{raw_nick})) {
		return 0;
	}

	foreach (@ignored) {
		my $temp = $_;
		$temp =~ s/\*/\.\+/g;

		if ($message->{raw_nick} =~ /$temp/i) {
			return 1;
		}
	}

	return 0;
}

1;