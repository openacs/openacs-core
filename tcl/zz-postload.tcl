# $Id$
# Name:        00-ad-postload.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        24 Feb 2000
# Description: Sources library files that need to be loaded after the rest.

set tcllib [ns_info tcllib]

ns_log "Notice" "Sourcing files for postload..."
foreach file [glob -nocomplain ${tcllib}/*.tcl.postload] {
    ns_log Notice "postloading $file"
    source "$file"
}
ns_log "Notice" "Done."

# This should probably be moved to the end of bootstrap.tcl once all files are
# weeded out of the tcl directory.
ns_log "Notice" "Executing initialization code blocks..."
foreach init_item [nsv_get ad_after_server_initialization .] {
    array set init $init_item

    ns_log "Notice" "Executing initialization code block $init(name) in $init(script)"
    if { [llength $init(args)] == 1 } {
	set init(args) [lindex $init(args) 0]
    }
    if { [catch $init(args) error] } {
	global errorInfo
	ns_log "Error" "Error executing initialization code block $init(name) in $init(script): $errorInfo"
    }
}

# OpenACS (ben)
# We need to load query files for the top-level stuff in www and tcl
set dirs {www tcl}
set oacs_root [acs_root_dir]

foreach dir $dirs {
    set files [glob -nocomplain "${oacs_root}/$dir/*.xql"]
    
    ns_log Notice "QD=Postload files to load: $files"

    foreach file $files {
	db_qd_load_query_file $file
    }
}

nsv_unset ad_after_server_initialization .
