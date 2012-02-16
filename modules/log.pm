package PinkieBot::Module::Log;
use base 'PinkieBot::Module';

use DBI;
use DateTime;

my %dbhsth;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Create needed tables if needed
	$self->createTableIfNotExists('activity', $message);

	# Prepared statements
	$dbhsth{activity} = $self->{bot}->{db}->prepare('INSERT INTO activity (type, timestamp, who, raw_nick, channel, body, address) VALUES (?, UNIX_TIMESTAMP(), ?, ?, ?, ?, ?);');

	# Register hooks
	$self->registerHook('said', \&handleSaid);
	$self->registerHook('emoted', \&handleEmoted);
	$self->registerHook('noticed', \&handleNoticed);
	$self->registerHook('chanjoin', \&handleChanJoin);
	$self->registerHook('chanpart', \&handleChanPart);
	$self->registerHook('topic', \&handleTopic);
	$self->registerHook('nick_change', \&handleNickChange);
	$self->registerHook('kicked', \&handleKicked);
	$self->registerHook('userquit', \&handleUserQuit);
	$self->registerHook('mode', \&handleMode);
}

sub handleSaid {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('said', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleEmoted {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('emote', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleNoticed {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('notice', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleChanJoin {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('chanjoin', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleChanPart {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('chanpart', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleTopic {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('topic', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleNickChange {
	my ($bot, $oldnick, $newnick) = @_;
	$dbhsth{activity}->execute('nickchange', $oldnick, undef, undef, $newnick, undef);
}

sub handleKicked {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('kicked', $message->{who}, $message->{kicked}, $message->{channel}, $message->{reason}, undef);
}

sub handleUserQuit {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('userquit', $message->{who}, undef, undef, $message->{body}, undef);
}

sub handleMode {
	my ($bot, $message) = @_;
	$dbhsth{activity}->execute('mode', undef, $message->{source}, $message->{channel}, ($message->{mode} . ' ' . $message->{args}), undef);
}

1;
