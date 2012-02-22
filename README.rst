About PinkieBot
###############
PinkieBot is yet another IRC bot and my attempt at learning the basics of Perl.
It's based off Bot::Basicbot with certain additions (irc invite and mode
events).

Influenced by Pinkie Pie from the new My Little Pony show with certain
catchphrases and random actions, she's been tailored specifically for an IRC
channel I'm frequently visiting and is guaranteed for some late night laughs
after a few beers.

PinkieBot is modularly built (since version 2.x.x) and using custom Perl Module
files in modules/\*.pm. Modules are able to register their own functions to IRC
hooks (like said, emoted, chanjoin, etc). Module loading is easy: Just stick the
right .pm file in modules/, make sure that any needed .sql schema files are
present in schemas/ and load the module! Using the default admin module, this is
through saying !load module. If there's any parse errors, PinkieBot will report
them and not crash the mane thread.

MySQL database and pinkiebot.ini configuration file is hardcoded into PinkieBot
and might be moved to modules on a later date.

Modules
=======
Admin
-----
Default administration module for PinkieBot. Do not unload it unless you want to
restart the whole PinkieBot process.

**Commands**:

*!list available*
    Lists all available modules. More specifically: modules/\*.pm files.
*!list loaded*
    Lists all loaded modules. Loaded modules are not neccessarily active.
*!list active*
    Lists all modules who are both loaded and active.
*!load module [args]*
    Loads a module with optional arguments.
*!unload module*
    Unloads a module.
*!reload module [args]*
    Reloads a module with optional arguments.
*!enable module*
    Enables a loaded and inactive module.
*!disable module*
    Disables a loaded and active module.
*!loaded module*
    Checks whether a module is loaded.
*!active module*
    Checks whether a module is active.
*!pinkiebot*
    Prints some info about the bot.

Google
------
Googles for a term and returns the topmost result.

**Commands**:

*!g query* or *!google query*
    Googles web pages  with said query and returns the first result.
!gi query* or *!gimage query* or *!googleimage query* or *!googleimages query*
    Googles images with said query and returns the first result.

Log
---
Records all raw activity in the database in the 'activity' table.

Quoter
------
Module to search and replace quotes people said in the same IRC channel.

*!s search replace*
    Searches for the latest line where $search is in, and replaces the first
    occurrence with $replace.
*!ss search replace*
    Searches for the latest line where $search is in, and replaces all
    occurrences with $replace.
*!sd word1 word2*
    Searches for the latest line where both $word1 and $word2 are in and
    switches them around.
*s/search/replace/[modifiers]*
    Regex replace. See your friendly neighbourhood Perl Regular Expression
    manual for usage. Supported optional modifiers are 'g' and 'i'.

RFC
---
Prints a summary of the RFC and links to a page with more information.

**Commands**:

*!rfc number*
    Searches for a RFC with said number.

Seen
----
Reports when and where a person has been last seen by the bot.

**Commands**:

*!seen person*
    Reports when the person was last seen by the bot.

Social
------
Some basic responses when interacting with the bot. Namely greeting the bot and
some friendly emotes (e.g. hugs, pats).

Title
-----
Posts the title when an URL is pasted in the chat. Does not work on certain URLs
and on https links, however.

Wikipedia
---------
Searches for an article on Wikipedia.org and prints the first ~300 characters of
the summary, with a link to the full article.

**Commands**:

*!w page* or *!wiki page*
    Searches for page on Wikipedia.org.
