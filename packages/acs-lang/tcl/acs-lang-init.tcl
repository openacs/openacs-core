ad_library {
    Do initialization at server startup for the acs-lang package.

    @creation-date 23 October 2000
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

# Load message catalog files from packages that don't have messages in the database already
# This is done in a scheduled proc so that it won't take up time at server startup.
# Instead, it can be done by a thread after the server has started multithreading.
# The proc also refreshes the message cache after having updated the database from the file system.

# PETER: Do we want this at all?

ad_schedule_proc -once t 5 lang::catalog::import_from_all_files_and_cache

# Load message catalog from the database to memory

lang::message::cache
