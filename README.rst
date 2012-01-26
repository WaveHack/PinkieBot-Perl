About PinkieBot
===============
PinkieBot is yet another IRC bot and my attempt at learning the basics of Perl.

Influenced by Pinkie Pie from the new My Little Pony show with certain
catchphrases and random actions, she's been tailored specifically for an IRC
channel I'm frequently visiting and is guaranteed for some late night laughs
after a few beers.

PinkieBot is built with function hooks to IRC events (said, emote, join, etc)
called modules. These are pretty basic and there's currently no way to disable,
re-enable or adjust config of said modules without modifying the source code,
yet.

PinkieBot uses from version 1.2 on a MySQL database for storing data (see
pinkiebot.sql). Support for SQLite might be readded in the future.

Commands
--------
**Karma**
::

    subject++
    subject--

*Example*::

    <Person> PHP++
    <PinkieBot> Karma for PHP is now 4.

**Seen**
::

    !seen name

*Example*::

    <PersonA> !seen personb
    <PinkieBot> PersonB was last seen in #channel 5m 36s ago saying "brb".

**Quote Replace**

Searches for the latest said or emote containing search, then
echoing the said or emote with search and replace. !s replaces the first
occurence. !ss replaces all occurences.
::

    !s search replace
    !ss search replace

*Example*::

    <PersonA> foo bar
    <PersonB> !s bar foobar
    <PinkieBot> <PersonA> foo foobar

**Quote Search**
::

    !q search

*Example*::

    <PersonA> !q youtube
    <PinkieBot> <RandomGuy> Hey guise check this: http://www.youtube.com/watch?v=oHg5SJYRHA0

**Quote Switch**

Switches around two words in the same sentence.
::

    !sd word1 word2

*Example*::

    <PersonA> foo bar
    <PersonB> !sd foo bar
    <PinkieBot> <PersonA> bar foo

Besides these explicit commands there are some more features in it:
 - Recording all activity in raw format to the database,
 - Slaps and corrects any neighsayer who misspell the words 'anypony', 'nopony'
   'everypony' and 'somepony'.
 - Doing her famous 'oatmeal'-quote from the show when someone types that word.
   The Dutch variant ('havermout') is also available.
 - Posting URL title if someone links an URL in the chat. This does not work
   with HTTPS links, however.
 - Punishes hostile emotes towards people on certain periods by kicking them if
   the bot is operator or half-operator.
