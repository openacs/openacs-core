ad_library {

    Set up the path to the spell-checker in an nsv cache.

    @cvs-id $Id$
    @author Ola Hansson (ola@polyxena.net)
    @creation-date 2003-10-04

}

# Find the aspell or, second best, the ispell binary.
# In case neither one is found, bin is empty and spell-checking will be disabled.
set bin [::util::which aspell]
if {$bin eq ""} {
  set bin [::util::which ispell]
}

# Do we want dialect dictionaries (if available) or not?
# Note that if you change this param it won't take effect
# until the server has been restarted. 
set dialects_p [parameter::get_from_package_key \
		    -package_key acs-templating \
		    -parameter SpellcheckDialectsP \
		    -default 0]

# aspell or ispell?
set dicts ""
set default_lang ""
#
# GN: note, that under windows, the binary will be called aspell.exe
#
if { [string match "*aspell*" $bin] } {
    # aspell
    with_catch errmsg {
        set dicts [exec $bin dump dicts]
        set default_lang [exec $bin config lang]
        if { !$dialects_p } {
            # If no dialects, then the default_lang locale returned from aspell
            # must be shortened to the first two letters, so that it matches
            # one of the names in the pull-down menu.
            set default_lang [string range $default_lang 0 1]
        }
    } {
        ns_log Warning "Gettings dicts and default_lang for aspell failed with error message: \"$errmsg\""
	ns_log Notice "You might want to upgrade to a more recent version of Aspell ... http://aspell.sourceforge.net/"
    }
} elseif { [string match "*ispell*" $bin] } {
    # ispell - if someone knows how to get the available dictionaries and the
    # default language from ispell, please add it here :-)
    set dicts ""
    set default_lang ""
} 

#Do we include all availabale dicts or not ?
set use_dicts_p [parameter::get_from_package_key \
		    -package_key acs-templating \
		    -parameter SpellcheckUseDictsP \
		    -default 0]

if {$use_dicts_p == 0} {
	set dicts ""
}	    
		    
# Build the select options list and filter out unwanted dictionaries.
set wanted_dicts [list {"No" :nospell:}]

if { $dicts eq "" } {
    # Just add the default locale (the empty string will work too).
    lappend wanted_dicts [list "Yes" $default_lang]
}

db_transaction {

    foreach dict $dicts {
	if { [string length $dict] == 2 } {
	    # We have a lang (e.g., en)
	    # Some 2-char aspell dicts (languages) are missing in ad_locales so we
	    # need to catch those cases and use the language as the pretty name, ugh ...
	    if { [catch { lappend wanted_dicts [list [string totitle [lang::util::nls_language_from_language $dict]] $dict] }] } {
	        lappend wanted_dicts [list "Locale $dict" $dict]
	    }
	    set last_dict $dict
	} elseif { $dialects_p && [string length $dict] == 5 && [regexp _ $dict] } {
	    # We have a locale (e.g., en_US)
	    if { [info exists last_dict] } {
		set wanted_dicts [lreplace $wanted_dicts end end]
		unset last_dict
	    }
	    # Some five-char aspell dicts (locales) are missing in ad_locales so we
	    # need to catch those cases and use the locale as the pretty name, ugh ...
	    if { [catch { lappend wanted_dicts [list [string totitle [lang::util::get_label $dict]] $dict] }] } {
		lappend wanted_dicts [list "Locale $dict" $dict]
	    }
	}
    }

} on_error {
    # Just add the default locale.
    lappend wanted_dicts [list "Yes" $default_lang]
}


#####
#
# Initialize the cache.
#
#####

nsv_set spellchecker path $bin
nsv_set spellchecker lang_options $wanted_dicts
nsv_set spellchecker default_lang $default_lang
