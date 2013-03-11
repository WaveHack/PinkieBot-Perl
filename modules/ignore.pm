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

	#$self->{bot}->{db}->prepare('SELECT host FROM ignored;');
}

sub handleSaidIgnore {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!ignore (.+)/);

	my $host = $1;

	# todo
}

sub handleSaidUnignore {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!unignore (.+)/);

	my $host = $1;

	# todo
}

sub handleSaidListIgnored {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!(list )?ignored/);

	# todo
}

sub ignoring {
	my ($module, $bot, $message) = @_;

	# todo

	# nickname!userid@host

	return 0;
}

1;
