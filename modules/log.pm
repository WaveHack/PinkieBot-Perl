package PinkieBot::Module::Log;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

my %dbsth;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Create needed tables if needed
	$self->createTableIfNotExists('activity', $message);

	# Prepared statements
	$dbsth{activity} = $self->{bot}->{db}->prepare('INSERT INTO activity (type, timestamp, who, raw_nick, channel, body, address) VALUES (?, UNIX_TIMESTAMP(), ?, ?, ?, ?, ?);');

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

	# Don't log PRIVMSGs
	return if ($message->{channel} eq 'msg');

	$dbsth{activity}->execute('said', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleEmoted {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('emote', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleNoticed {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('notice', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleChanJoin {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('chanjoin', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleChanPart {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('chanpart', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleTopic {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('topic', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleNickChange {
	my ($bot, $oldnick, $newnick) = @_;
	$dbsth{activity}->execute('nickchange', $oldnick, undef, undef, $newnick, undef);
}

sub handleKicked {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('kicked', $message->{who}, $message->{kicked}, $message->{channel}, $message->{reason}, undef);
}

sub handleUserQuit {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('userquit', $message->{who}, undef, undef, $message->{body}, undef);
}

sub handleMode {
	my ($bot, $message) = @_;
	$dbsth{activity}->execute('mode', undef, $message->{source}, $message->{channel}, ($message->{mode} . ' ' . $message->{args}), undef);
}

1;
