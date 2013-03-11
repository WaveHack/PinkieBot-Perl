package PinkieBot::Module::Ddg;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

use WWW::DuckDuckGo;

my $ddg;

sub init {
	my ($self, $bot, $message, $args) = @_;

	$ddg = WWW::DuckDuckGo->new;

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!ddg (.+)/);

	my $searchTerm = $1;
	my $zci = $ddg->zci($1);

	if ($zci->has_answer) {
		$bot->reply(('DDG Answer: ' . $zci->heading . ': ' . $zci->answer), $message);
		return;
	}

	if ($zci->has_definition) {
		$bot->reply(('DDG Definition: ' . $zci->heading . ': ' . $zci->definition), $message);
		return;
	}

	if ($zci->has_abstract_text) {
		$bot->reply(('DDG Abstract Text: ' . $zci->heading . ': ' . $zci->abstract_text), $message);
		return;
	}
}

1;

