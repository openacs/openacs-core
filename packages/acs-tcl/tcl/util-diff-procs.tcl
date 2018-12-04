ad_library {
    Procedures to generate pretty formatted diffs of some text
}

namespace eval util:: {}

ad_proc -public util::diff {
    -old
    -new
    {-show_old_p "t"}
} {
    Perform a UNIX diff on 'old' and 'new', and return a HTML fragment of the changes.

    Requires struct::list (from tcllib)

    @author Vinod Kurup vinod@kurup.com
    @creation-date 2005-10-18

    @param old original text
    @param new new text
    @return HTML fragment of differences between 'old' and 'new'
} {
    package require struct::list

    set old [split $old " "]
    set new [split $new " "]

    # tcllib procs to get a list of differences between 2 lists
    # see: http://tcllib.sourceforge.net/doc/struct_list.html
    set len1 [llength $old]
    set len2 [llength $new]
    set result [::struct::list longestCommonSubsequence $old $new]
    set result [::struct::list lcsInvert $result $len1 $len2]

    # each chunk is either 'deleted', 'added', or 'changed'
    set i 0
    foreach chunk $result {
        ns_log notice "\n$chunk\n"
        set action [lindex $chunk 0]

        lassign [lindex $chunk 1] old_index1 old_index2
        lassign [lindex $chunk 2] new_index1 new_index2

        while {$i < $old_index1} {
            lappend output [lindex $old $i]
            incr i
        }

        if { $action eq "changed" } {
            if {$show_old_p} {
                lappend output <d>
                foreach item [lrange $old $old_index1 $old_index2] {
                    lappend output [string trim $item]
                }
                lappend output </d>
            }
            lappend output <a>
            foreach item [lrange $new $new_index1 $new_index2] {
                lappend output [string trim $item]
            }
            lappend output </a>
            incr i [expr {$old_index2 - $old_index1 + 1}]
        } elseif { $action eq "deleted" } {
            lappend output <d>
            foreach item [lrange $old $old_index1 $old_index2] {
                lappend output [string trim $item]
            }
            lappend output </d>
            incr i [expr {$old_index2 - $old_index1 + 1}]
        } elseif { $action eq "added" } {
            while {$i < $old_index2} {
                lappend output [lindex $old $i]
                incr i
            }
            lappend output <a>
            foreach item [lrange $new $new_index1 $new_index2] {
                lappend output [string trim $item]
            }
            lappend output </a>
        }
    }

    # add any remaining words at the end.
    while {$i < $len1} {
        lappend output [lindex $old $i]
        incr i
    }

    set output [join $output " "]
    set output [string map {"<d>" {<span class="diff-deleted">}
        "</d>" </span>
        "<a>" {<span class="diff-added">}
        "</a>" </span>} $output]

    return "$output"
}


ad_proc -public util::html_diff {
    -old
    -new
    {-show_old_p "t"}
} {
    Perform a UNIX diff on 'old' and 'new', and return a HTML fragment of the changes.

    Requires struct::list (from tcllib)

    @author Vinod Kurup vinod@kurup.com
    @creation-date 2005-10-18

    @param old original text
    @param new new text
    @return HTML fragment of differences between 'old' and 'new'
} {
    package require struct::list

    set frag $old
    set old_list [list]
    while {$frag ne ""} {
        if {![regexp "(\[^<]*)(<(/?)(\[^ \r\n\t>]+)(\[^>]*)>)?(.*)" $frag match pretag fulltag close tag tagbody frag]} {
            # should never get here since above will match anything.
            ns_log Error "util_close_html_tag - NO MATCH: should never happen! frag=$frag"
            lappend old_list $frag
            set frag {}
        }
        if {$pretag ne ""} {
            set pretag [string map {\n " "} $pretag]
            set pretag2 [list]
            foreach element [split $pretag " "] {
                if {[string trim $element] ne ""} {
                    lappend pretag2 [string trim $element]
                }
            }
            if {[llength $pretag2]} {
                lappend old_list {*}$pretag2
            }
        }
        if {$fulltag ne ""} {
            lappend old_list $fulltag
        }
    }

    set frag $new
    set new_list [list]
    while {$frag ne ""} {
        if {![regexp "(\[^<]*)(<(/?)(\[^ \r\n\t>]+)(\[^>]*)>)?(.*)" $frag match pretag fulltag close tag tagbody frag]} {
            # should never get here since above will match anything.
            lappend new_list $frag
            set frag {}
        }
        if {$pretag ne ""} {
            set pretag [string map {\n " "} $pretag]
            set pretag2 [list]
            foreach element [split $pretag " "] {
                if {[string trim $element] ne ""} {
                    lappend pretag2 [string trim $element]
                }
            }
            if {[llength $pretag2]} {
                lappend new_list {*}$pretag2
            }
        }
        if {$fulltag ne ""} {
            lappend new_list $fulltag
        }
    }
    # tcllib procs to get a list of differences between 2 lists
    # see: http://tcllib.sourceforge.net/doc/struct_list.html
    set len1 [llength $old_list]
    set len2 [llength $new_list]
    set result [::struct::list longestCommonSubsequence $old_list $new_list]
    set result [::struct::list lcsInvert $result $len1 $len2]

    # each chunk is either 'deleted', 'added', or 'changed'
    set i 0
    set last_chunk ""
    foreach chunk $result {

        set action [lindex $chunk 0]

        lassign [lindex $chunk 1] old_index1 old_index2
        lassign [lindex $chunk 2] new_index1 new_index2

        while {$i < $old_index1} {
            lappend output [lindex $old_list $i]
            incr i
        }
        if { $action eq "changed" } {
            if {$show_old_p} {
                #ns_log notice "adding <@d@>"
                lappend output <@d@>
                foreach item [lrange $old_list $old_index1 $old_index2] {
                    if {![string match "<*>" [string trim $item]]} {
                        #ns_log notice "deleting item '${item}'"
                        # showing deleted tags is a bad idea.
                        lappend output [string trim $item]
                    } else {
                        ns_log notice "SKIPPED DELETE of tag $item"
                    }

                }
                #ns_log notice "adding </@d@>"
                lappend output </@d@>
            }
            #ns_log notice "adding <@a@>"
            lappend output <@a@>
            foreach item [lrange $new_list $new_index1 $new_index2] {
                if {![string match "<*>" [string trim $item]]} {
                    #ns_log notice "adding item '${item}'"
                    lappend output [string trim $item]
                } else {
                    lappend output </@a@>${item}<@a@>
                    #ns_log notice "adding</@a@>${item}<@a@>"
                }
            }
            #ns_log notice "adding </@a@>"
            lappend output </@a@>
            incr i [expr {$old_index2 - $old_index1 + 1}]
        } elseif { $action eq "deleted" } {
            lappend output <@d@>
            foreach item [lrange $old_list $old_index1 $old_index2] {
                lappend output [string trim $item]
            }
            lappend output </@d@>
            incr i [expr {$old_index2 - $old_index1 + 1}]
        } elseif { $action eq "added" } {
            while {$i < $old_index2} {
                #ns_log notice "unchanged item"
                lappend output [lindex $old_list $i]
                incr i
            }
            lappend output <@a@>
            foreach item [lrange $new_list $new_index1 $new_index2] {
                if {![string match "<*>" [string trim $item]]} {
                    #ns_log notice "adding item"
                    lappend output [string trim $item]
                }
            }
            lappend output </@a@>
        }
    }

    # add any remaining words at the end.
    while {$i < $len1} {
        lappend output [lindex $old_list $i]
        incr i
    }

    set output [join $output " "]
    set output [string map {"<@d@>" {<span class="diff-deleted">}
        "</@d@>" </span>
        "<@a@>" {<span class="diff-added">}
        "</@a@>" </span>} $output]

    return "$output"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
