#!/bin/sh

# Credit goes to many random people who have contributed to and
# improved this file. May need to be tweaked to work better for OpenACS

if ( test $# != 1 ) then
  echo "Usage: etags.sh <path to root repository checkout>"
  echo "  example: etags.sh /web/vs/trunk"
  echo "  if you are in /web/vs directory, you can do etags.sh ."
  exit
fi

# Creates an etags file of our tree. 

find $1 -type f -regex ".*\.\([tcl|adp]+\)$" -print | etags --lang=none --regex='/ad_proc\([ \t]\)+\(-public\)?\(-protected\)?\(-private\)?\([ \t]\)*\([^ \t]+\)/\4/' --regex='/proc_doc[ \t]+\([^ \t]+\)/\1/' --regex='/proc[ \t]+\([^ \t]+\)/\1/' -
