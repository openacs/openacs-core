ad_library {
    Debug procs
}

ad_proc -public watch_files {} {
    tracks each file by interpreter to ensure that it is up-to-date
} {
    set files {
        ats/paginator-procs.tcl
        ats/query-procs.tcl
        ats/debug-procs.tcl
        ats/filter-procs.tcl
        ats/util-procs.tcl
    }

    foreach file $files { 

        set file $::acs::tcllib/$file

        set proc_name [info commands ::template::mtimes::tcl::$file]
        set mtime [file mtime $file]
        
        if { $proc_name eq {} || $mtime != [$proc_name] } {

            uplevel #0 "source $file"
            proc ::template::mtimes::tcl::$file {} "return $mtime"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
