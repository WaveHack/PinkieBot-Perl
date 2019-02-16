package PinkieBot::Module::Reload;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

sub init {
	my ($self, $bot, $message, $args) = @_;

	# Register hooks
	$self->registerHook('said', \&handleSaidReloadModule);
}

sub handleSaidReloadModule {
	my ($bot, $message) = @_;

	return unless ($bot->addressed($message) && ($message->{body} =~ /^reload(?: module)? ([^ ]+)(?: (.+))?/));
	return if ($bot->moduleActive('auth') && !$bot->module('auth')->checkAuthorization($bot, $message, 7));

	my $module = $1;
	my $args   = $2;

	# Check if we're reloading multiple modules. Arguments are not supported here
	if ($module =~ /,/) {
		my @modules = split(',', $module);

		foreach (@modules) {
			my $ret = $bot->reloadModule($_, $message);
			$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
		}

	# Single module, arguments supported
	} else {
		my $ret = $bot->reloadModule($module, $message, $args);
		$bot->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
	}
}

1;
