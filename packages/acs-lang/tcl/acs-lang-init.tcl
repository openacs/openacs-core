ad_library {
    Do initialization at server startup for the acs-lang package.

    @creation-date 23 October 2000
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id$
}

# This is done in a scheduled proc so that it won't take up time at server startup.
ad_schedule_proc -once t 5 lang::catalog::import -initialize -cache
