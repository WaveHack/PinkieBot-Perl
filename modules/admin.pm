package PinkieBot::Module::Admin;
use base 'PinkieBot::Module';

sub init {
	my $self = shift;

	$self->registerHook('said', \&handleSaid);
	$self->registerHook('invited', \&handleInvited);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless checkPerms($message->{raw_nick});

	my $ret;

	if ($message->{body} =~ /^!list available$/) { $ret = ('Available modules: ' . join(', ', sort($bot->getAvailableModules()))); }
	if ($message->{body} =~ /^!list loaded$/)    { $ret = ('Loaded modules: ' . join(', ', sort($bot->getLoadedModules()))); }
	if ($message->{body} =~ /^!list active$/)    { $ret = ('Active modules: ' . join(', ', sort($bot->getActiveModules()))); }
	if ($message->{body} =~ /^!load (.*)/)       { $ret = $bot->loadModule($1); }
	if ($message->{body} =~ /^!unload (.*)/)     { $ret = $bot->unloadModule($1); }
	if ($message->{body} =~ /^!reload (.*)/)     { $ret = $bot->reloadModule($1); }
	if ($message->{body} =~ /^!enable (.*)/)     { $ret = $bot->enableModule($1); }
	if ($message->{body} =~ /^!disable (.*)/)    { $ret = $bot->disableModule($1); }
	if ($message->{body} =~ /^!loaded (.*)/)     { $ret = $bot->moduleLoaded($1); }
	if ($message->{body} =~ /^!active (.*)/)     { $ret = $bot->moduleActive($1); }
	if ($message->{body} =~ /^!pinkiebot$/)      { $ret = $bot->help(); }

	return unless defined($ret);

	$bot->say(
		who     => $message->{who},
		channel => $message->{channel},
		body    => ((ref(\$ret) eq "SCALAR") ? $ret : "$ret->{string} [S:$ret->{status} C:$ret->{code}]"),
		address => $message->{address}
	);
}

sub handleInvited {
	my ($bot, $message) = @_;

	return unless checkPerms($message->{raw_nick});

	$bot->join_channel($message->{channel});
}

sub checkPerms {
	my $host = shift;

	return (
		($host =~ /WaveHack\@wavehack\.net$/) ||
		($host =~ /vanillabea\@Sexy\.Stallion$/) ||
		($host =~ /hydrazine\@rainbow\.factory$/) ||
		($host =~ /nido\@tgpgrzxyzd\.foxserver\.be$/)
	) ? 1 : 0;
}

1;
