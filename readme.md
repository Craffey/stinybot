# Stinybot

Steps to run:

1. Run perl stinybot.pl
2. ctrl+c to stop

Input Sanitization:

Since stinybot runs on a local terminal, it is important that no commands can be passed to it that allow users to run any command they like. This behavior is prevented by parsing all commands to remove all backtick marks, which would cause perl to execute arguments as shell commands. In my experiments, the backticks do not evaluate until the call to send a message, so cleaning them right after pulling the command into its own variable should be sufficient. 

Perl Dependencies:

1. DBI [Installing Perl/DBI support on Unix and Mac OS X](http://dcx.sybase.com/1200/en/dbprogramming/dbd-sqlany-install-unix.html) (install DBI perl module section)
2. Switch
   1. sudo cpan
   2. install Switch


## Resources

1. [Jared](https://github.com/ZekeSnider/Jared)
2. [Using SQL to Look Through All of Your iMessage Text Messages](https://spin.atomicobject.com/2020/05/22/search-imessage-sql/)
