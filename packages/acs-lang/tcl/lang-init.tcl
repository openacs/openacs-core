#/packages/lang/tcl/lang-init.tcl
ad_library {

    Initializes the message cache.
    Registers the ADP tag.
    Loads files that contain messages.
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @cvs-id $Id$
}


# We segregate messages by language. It might reduce contention
# if we segregage instead by package. Check for problems with ns_info locks.

set i 0 
db_foreach select_lang_keys "\
	select key \
	,rtrim(lang) as lang \
	,message \
	from lang_messages" {
    nsv_set lang_message_$lang $key $message
    incr i
}
db_release_unused_handles

ns_log Notice "Initialized message table; got $i rows"

#ns_register_adptag trn {/trn} lang_tag_translate

ad_schedule_proc -once t 5 lang_catalog_load


