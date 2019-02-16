package PinkieBot::Module::Ddg;
use base 'PinkieBot::Module';
use warnings;
no warnings 'redefine';
use strict;

use WWW::DuckDuckGo;

my $duck;

sub init {
	my ($self, $bot, $message, $args) = @_;

	$duck = WWW::DuckDuckGo->new(safeoff => '1');

	# Register hooks
	$self->registerHook('said', \&handleSaid);
}

sub handleSaid {
	my ($bot, $message) = @_;

	return unless ($message->{body} =~ /^!ddg (.+)/);

	my $searchTerm = $1;
	my $zci = $duck->zeroclickinfo($1);
	# $bot->reply(('DDG query: ' . $searchTerm), $message);

	$bot->say({%$message, body => "Redirected to " . $zci->redirect}) if $zci->has_redirect;

	if ($zci->has_answer) {
		$bot->reply(('DDG Answer: ' . $zci->heading . ': ' . $zci->answer), $message);
		return;
	}

	if ($zci->has_heading) {
		my $heading = $zci->heading;
		$heading .= " (" . $zci->type_long . ")" if $zci->has_type;
		$bot->say({%$message, body => $heading});
	}

	if ($zci->has_definition) {
		$bot->reply(('DDG Definition: ' . $zci->heading . ': ' . $zci->definition), $message);
		return;
	}

	if ($zci->has_abstract_text) {
		$bot->reply(('DDG Abstract Text: ' . $zci->heading . ': ' . $zci->abstract_text), $message);
		return;
	}

	if ($zci->type_long eq 'disambiguation') {

		if ($zci->has_default_related_topics) {
			$bot->say({%$message, body => "Related topics:"});

			for (@{$zci->default_related_topics}) {
				if ($_->has_text or $_->has_first_url) {
					my $topic = ' — ';
					$topic .= $_->text if $_->has_text;
					$topic .= ' [' if $_->has_text and $_->has_first_url;
					$topic .= $_->first_url->as_string if $_->has_first_url;
					$topic .= ']' if $_->has_text and $_->has_first_url;
					$bot->say({%$message, body => $topic});
				}
			}
		}

		if ($zci->has_results) {
			$bot->say({%$message, body => "Other results:"});
			for (@{$zci->results}) {
				if ($_->has_text or $_->has_first_url) {
					my $result = ' — ';
					$result .= $_->text if $_->has_text;
					$result .= ' [' if $_->has_text and $_->has_first_url;
					$result .= $_->first_url->as_string if $_->has_first_url;
					$result .= ']' if $_->has_text and $_->has_first_url;
					$bot->say({%$message, body => $result});
				}
			}
		}
	}
}

1;
