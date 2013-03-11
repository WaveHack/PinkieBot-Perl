PinkieBot
#########

About
=====
PinkieBot is yet another IRC bot and my attempt at learning the basics of Perl. It's based off Bot::Basicbot with certain additions (irc invite and mode events).

Influenced by Pinkie Pie from the new My Little Pony show with certain catchphrases and random actions, she's been tailored specifically for an IRC channel I'm frequently visiting and is guaranteed for some late night laughs after a few beers.

PinkieBot is modularly built (since version 2.x.x) and using custom Perl Module files in modules/\*.pm. Modules are able to register their own functions to IRC hooks (like said, emoted, chanjoin, etc). Module loading is easy: Just stick the right .pm file in modules/, make sure that any needed .sql schema files are present in schemas/ and load the module! Using the default admin module, this is through saying !load module. If there's any parse errors, PinkieBot will report them and not crash the mane thread.

MySQL database and pinkiebot.ini configuration file is hardcoded into PinkieBot and might be moved to modules on a later date.

Legal
=====
PinkieBot is licensed under the DBAD license, which can be found here: http://philsturgeon.co.uk/code/dbad-license

The PinkieBot logo (pinkiebot.png) is made and (c) Copyright by `secret-pony <http://secret-pony.deviantart.com/art/Pinkiebot-286224629>`_ on DeviantArt.

Modules
=======
Numbers behind the commands indicate the required authorization level to perform that command. Levels with an asterisk require the Auth module to be loaded. There's no set lines for authorization levels, but I generally use the following rules:

    * -1 - Not authenticated
    * 0-5 - User levels
    * 6 - Readonly administration (module status, user listing)
    * 7 - Module administration (loading, unloading)
    * 8 - User management and bot updating
    * 9 - Arbitairy Perl/Shell commands

One can have as many auth levels as the size of your database field (sizeof int, usually). Do note that higher auth levels include lower auth levels, since auth checking is done with >=.

Round brackets () in a command indicate that that parameter is required and the commmand will use that parameter for the functionality it's supposed to do. Square brackets [] indicate that that argument is optional and can be omitted.

Admin
-----
Default administration module for PinkieBot. Do not unload it unless you want to restart the whole PinkieBot process. Without the Admin module loaded, nobody can control the bot.

If you have the Auth module loaded, almost all of these Admin commands require you to be logged in in the Auth module. The 'eval' and 'cmd' functions are disabled if the Auth module isn't loaded to prevent abuse.

Due to request, listing modules (all, loaded and active) are available to see for people who are not logged in.

**Commands**:

*list all [modules]*
    Lists all modules, grouped by active, loaded and available.
*list available [modules]*
    Lists all available modules. More specifically: modules/\*.pm files.
*list loaded [modules]*
    Lists all loaded modules. Loaded modules are not neccessarily active.
*list active [modules]*
    Lists all modules who are both loaded and active.
*load (module) [arg1 [arg2 [...]]]* (7)
    Loads a module with optional arguments.
*load (module[,module2[,module3]])* (7)
    Loads multiple modules, but arguments are not supported.
*unload (module[,module2[,module3]])* (7)
    Unloads one or multiple modules.
*reload (module) [arg1 [arg2 [...]]]* (7)
    Reloads a module with optional arguments.
*reload (module[,module2[,module3]])* (7)
    Reoads multiple modules, but arguments are not supported.
*enable (module)* (7)
    Enables a loaded and inactive module.
*disable (module)* (7)
    Disables a loaded and active module.
*(module) loaded*
    Checks whether a module is loaded.
*(module) active*
    Checks whether a module is active.
*update* (8)
    Updates the bot's code from the repository.
*eval (cmd)* (9*)
    Eval's some Perl code.
*cmd (cmd)* (9*)
    Runs arbitrairy shell code.
*!pinkiebot* or *pinkiebot?*
    Prints some info about the bot.
*chanjoin (channel)* (7)
    Joins a channel.
*chanpart (channel)* (7)
    Parts (leaves) a channel.

Auth
----
Without the Auth module, anyone has access to the Admin functions (except for 'eval' and 'cmd'). Highly recommended to keep active at all times, unless you're testing/developing in a secluded channel.

Logins are based on raw nick, which is nickname!username@vhost. Be cautious with shared (v)hosts, as login sessions can be stolen this way. Logins persist after chanpart/quit.

**Commands**:

*login (username) (password)*
    Logs you in.
*logout* (0)
    Logs you out.
*whoami* (0)
    Prints your raw nick and authorization level.
*list users* (8)
    Prints a list of current logged in usernames.
*list usernames* (8)
    Prints a list of available usernames+levels from the database.
*adduser (username) (password) [level]]* (8)
    Adds a user to the database. Level is 0 if omitted.
*deluser (username)* (8)
    Removes a user from the database.
*changelevel (username) (level)* (8)
    Changes authorization level of selected user. Can only be your own authorization level or lower (not higher).

Cupcakes
--------
Responds with a random phrase or emote when someone mentions the word 'cupcakes'.

Google
------
Googles for a term and returns the topmost result.

**Commands**:

*!g (query)*
    Googles web pages  with said query and returns the first result.
*!gi (query)*
    Googles images with said query and returns the first result.

Log
---
Records all raw activity in the MySQL database in the 'activity' table.

MLFW
----
My Little Face When module.

**Commands**:

*!mlfw (tag1)[,tag2[,tag3[...]]]*
    Searches MLFW for the tags and returns one random result.
*>mlfw [anything]*
    Fetches a completely random MLFW.

Oatmeal
-------
Responds with 'Oatmeal? Are you crazy?!' when someone mentions the word 'oatmeal'.

Also contains the Dutch variant 'havermout'.

Quoter
------
Module to search and replace quotes people said in the same IRC channel.

**Commands**:

*!s (search) (replace)*
    Searches for the latest line where $search is in, and replaces the first occurrence with $replace.
*!ss (search) (replace)*
    Searches for the latest line where $search is in, and replaces all occurrences with $replace.
*!sd (word1) (word2)*
    Searches for the latest line where both $word1 and $word2 are in and switches them around.
*s/(search)/(replace)/[modifiers]*
    Regex replace. See your friendly neighbourhood Perl Regular Expression manual for usage. Supported optional modifiers are 'g' and 'i'. There's hacked-in support for the full search string in the form of capture group 0 (\0).
*q/(search)/[modifiers]*
	Regex search. Essentially a s/search/\\0/[modifiers] wrapper. Supported modifier is 'i', but is not yet implemented due to misconfigured MySQL schema. :D

RFC
---
Prints a summary of the RFC and links to a page with more information.

**Commands**:

*!rfc (number)*
    Searches for a RFC with said number.

RSS
---
Module to fetch RSS updates for various feeds.

Todo: more info

Seen
----
Reports when and where a person has been last seen by the bot.

**Commands**:

*!seen (name)*
    Reports when the person was last seen by the bot.

Social
------
Some basic responses when interacting with the bot. Namely greeting the bot and some friendly emotes (e.g. hugs, pats). See the module code for full list.

Synchtube
---------
Module which posts the title of a Synchtube room, if it exists.

**Commands**:

*!st (room)* or *!synchtube (room)*
    Posts the title of the Synchtube room.

Title
-----
Posts the title when an URL is pasted in the chat. Does not work on certain URLs and on https links, however.

Urbandict
---------
Searches for an Urban Dictionary definition and posts the first result.

**Commands**:

*!ud (definition)*
    Posts the first Urban Dictionary definition result.

Watch
-----
Keeps an eye on when somebody is back. When a person is back (when they say or emote in a channel), the bot addresses the watcher that the watched person has returned.

**Commands**:

*!watch (name)*
    Watches a person.

Wikipedia
---------
Searches for an article on Wikipedia.org and prints the first ~300 characters of the summary, with a link to the full article.

**Commands**:

*!w (page)* or *!wiki (page)*
    Searches for page on Wikipedia.org.
