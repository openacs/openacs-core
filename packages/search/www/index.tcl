ad_page_contract {
    @author Jeff Davis <davis@xarg.net>
    @creation-date 2005-02-01
    @cvs-id $Id$
} {}

set driver [ad_parameter -package_id [ad_conn package_id] FtsEngineDriver]
array set info [acs_sc_call FtsEngineDriver info [list] $driver]
if { [array get info] == "" } {
    # no driver present  need a warning.
    set driver_p 0
} else {
    set driver_p 1
}
