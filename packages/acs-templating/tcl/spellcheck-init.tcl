ad_library {

    Set up the path to the spell-checker in an nsv cache.

    @cvs-id $Id$
    @author Ola Hansson (ola@polyxena.net)
    @creation-date 2003-10-04

}

# Find the aspell or, second best, the ispell binary.
# In case neither one is found, spell-checking will be disabled.

set bin [ad_decode [catch {exec which aspell}] \
	     0 [exec which aspell] \
	     [ad_decode [catch {exec which ispell}] \
		  0 [exec which ispell] \
		  ""]]

nsv_set spellchecker path $bin
