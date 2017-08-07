ad_library {

    Routines for generating API documentation.

    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@arsdigita.com)
    @creation-date 21 Jun 2000
    @cvs-id $Id$

}

namespace eval ::apidoc {

    if {[ns_info name] eq "NaviServer"} {
        #
        # NaviServer at sourceforge
        #
        set ns_api_host  "http://naviserver.sourceforge.net/"
        set ns_api_index [list "n/naviserver/files/" "n/"]
        set ns_api_root  [list \
                              ${ns_api_host}[lindex $ns_api_index 0] \
                              ${ns_api_host}[lindex $ns_api_index 1] ]
        set ns_api_html_index [list \
                                   [lindex $ns_api_root 0]commandlist.html \
                                   [lindex $ns_api_root 1]toc.html ]
    } else {
        #
        # AOLserver wiki on panpotic
        #
        set ns_api_host  "http://panoptic.com/"
        set ns_api_index "wiki/aolserver/Tcl_API"
        set ns_api_root ${ns_api_host}${ns_api_index}
        set ns_api_html_index $ns_api_root
    }

    set tcl_api_html_index "http://www.tcl.tk/man/tcl$::tcl_version/TclCmd/contents.htm"

    # set style {
    #     .code .comment  {color: #006600; font-weight: normal; font-style: italic;}
    #     .code .keyword  {color: #0000AA; font-weight: bold;   font-style: normal;}
    #     .code .string   {color: #990000; font-weight: normal; font-style: italic;}
    #     .code .var      {color: #660066; font-weight: normal; font-style: normal;}
    #     .code .proc     {color: #0000CC; font-weight: normal; font-style: normal;}
    #     .code .object   {color: #000066; font-weight: bold;   font-style: normal;}
    #     .code .helper   {color: #0000CC; font-weight: bold;   font-style: normal;}
    #     pre.code a      {text-decoration: none;}
    # }
    set style {
        .code .comment  {color: #717ab3; font-weight: normal; font-style: italic;}
        .code .keyword  {color: #7f0055; font-weight: normal; font-style: normal;}
        .code .string   {color: #779977; font-weight: normal; font-style: italic;}
        .code .var      {color: #AF663F; font-weight: normal; font-style: normal;}
        .code .proc     {color: #0000CC; font-weight: normal; font-style: normal;}
        .code .object   {color: #000066; font-weight: bold;   font-style: normal;}
        .code .helper   {color: #aaaacc; font-weight: bold;   font-style: normal;}
        pre.code        {
            background: #fefefa; 
            border-color: #aaaaaa; 
            border-style: solid;
            border-width: 1px; 
            /*width: 900px; overflow: auto;*/
        }
        pre.code a      {text-decoration: none;}
    }

    set KEYWORDS {

        after append apply array bgerror binary break catch cd chan
        clock close concat continue default dict encoding eof error
        eval exec expr fblocked fconfigure fcopy file fileevent flush
        for foreach format gets glob global if incr info interp join
        lappend lassign lindex linsert list llength load lrange
        lreplace lreverse lsearch lset lsort namespace open package
        pid proc puts pwd read refchan regexp regsub rename return
        scan seek set socket source split string subst switch tell
        time trace unload unset update uplevel upvar variable vwait
        while

    }

}


ad_proc -public api_read_script_documentation {
    path
} {

    Reads the contract from a Tcl content page.

    @param path the path of the Tcl file to examine, relative to the
    OpenACS root directory.
    @return a list representation of the documentation element array, or
    an empty list if the file does not contain a <code>doc_page_contract</code>
    block.
    @error if the file does not exist.

} {
    # First, examine the file to determine whether the first non-comment
    # line begins with the string "ad_page_contract".
    set has_contract_p 0

    if { ![file exists "$::acs::rootdir/$path"] } {
        return -code error "File $path does not exist"
    }

    set file [open "$::acs::rootdir/$path" "r"]
    while { [gets $file line] >= 0 } {
        # Eliminate any comment characters.
        regsub -all {\#.*$} $line "" line
        set line [string trim $line]
        if { $line ne "" } {
            set has_contract_p [regexp {(^ad_(page|include)_contract\s)|(Package initialize )} $line]
            break
        }
    }
    close $file

    if { !$has_contract_p } {
        return [list]
    } 

    doc_set_page_documentation_mode 1
    #ns_log notice "Sourcing $::acs::rootdir/$path in documentation mode"
    set errno [catch { source "$::acs::rootdir/$path" } error]
    doc_set_page_documentation_mode 0
    
    #
    # In documentation mode, we expect ad_page_contract (and counterparts)
    # to break out of sourcing with an error to avoid side-effects of sourcing
    #
    if { $errno == 1} {
        if {[regexp {^ad_page_contract documentation} $::errorInfo] } {
            array set doc_elements $error
        }
        if { [array exists doc_elements] } {
            return [array get doc_elements]
        }
        return [list]
    }

    return -code $errno -errorcode $::errorCode -errorinfo $::errorInfo $error
}

ad_proc -public api_script_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a content page. Sources the file
    to obtain the comment or contract at the beginning.

    @param format the type of documentation to generate. Currently, only
    <code>text/html</code> is supported.
    @param path the path of the Tcl file to examine, relative to the
    OpenACS root directory.
    @return the formatted documentation string.
    @error if the file does not exist.

} {
    append out "<h3>[file tail $path]</h3>\n"

    # If it's not a Tcl file, we can't do a heck of a lot yet. Eventually
    # we'll be able to handle ADPs, at least.
    if {[file extension $path] eq ".xql"} {
        append out "<blockquote>DB Query file</blockquote>\n"
        return $out
    } elseif { [file extension $path] ne ".tcl" } {
        set mime_type [ns_guesstype $path]
        if {[string match image/* $mime_type] && [regexp {packages/(.*)/www/resources/(.*)$} $path . pkg name]} {
            set preview "<p><img src='/resources/$pkg/$name'>"
        } else {
            set preview ""
        }
        append out "<blockquote><p><i>Delivered as $mime_type</i>$preview</blockquote>\n"
        return $out
    }

    if { [catch { array set doc_elements [api_read_script_documentation $path] } error] } {
        append out "<blockquote><p><i>Unable to read $path: [ns_quotehtml $error]</i></blockquote>\n"
        return $out
    }

    array set params [list]

    if { [info exists doc_elements(param)] } {
        foreach param $doc_elements(param) {
            if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
                set params($name) $value
            }
        }
    }
    
    append out "<blockquote>"
    if { [info exists doc_elements(main)] } {
        append out <p>[lindex $doc_elements(main) 0]
    } else {
        append out "<p><i>Does not contain a contract.</i>"
    }
    append out "<dl>\n"
    # XXX: This does not work at the moment. -bmq
    #     if { [array size doc_elements] > 0 } {
    #         array set as_flags $doc_elements(as_flags)
    #     array set as_filters $doc_elements(as_filters)
    #         array set as_default_value $doc_elements(as_default_value)

    #         if { [llength $doc_elements(as_arg_names)] > 0 } {
    #         append out "<dt><b>Query Parameters:</b><dd>\n"
    #         foreach arg_name $doc_elements(as_arg_names) {
    #         append out "<b>$arg_name</b>"
    #         set notes [list]
    #         if { [info exists as_default_value($arg_name)] } {
    #             lappend notes "defaults to <code>\"$as_default_value($arg_name)\"</code>"
    #         } 
    #          set notes [concat $notes $as_flags($arg_name)]
    #         foreach filter $as_filters($arg_name) {
    #             set filter_proc [ad_page_contract_filter_proc $filter]
    #             lappend notes "<a href=\"[api_proc_url $filter_proc]\">$filter</a>"
    #         }
    #         if { [llength $notes] > 0 } {
    #             append out " ([join $notes ", "])"
    #         }
    #         if { [info exists params($arg_name)] } {
    #             append out " - $params($arg_name)"
    #         }
    #         append out "<br>\n"
    #         }
    #         append out "</dd>\n"
    #     }
    #     if { [info exists doc_elements(type)] && $doc_elements(type) ne "" } {
    #         append out "<dt><b>Returns Type:</b><dd><a href=\"type-view?type=$doc_elements(type)\">$doc_elements(type)</a>\n"
    #     }
    #     # XXX: Need to support "Returns Properties:"
    #     }
    append out "<dt><b>Location:</b><dd>$path\n"
    append out [::apidoc::format_common_elements doc_elements]

    append out "</dl></blockquote>"

    return $out
}

ad_proc -public api_library_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a Tcl library file (just the header,
                                                              describing what the library does).

    @param path the path to the file, relative to the OpenACS path root.

} {
    if { $format ne "text/html" } {
        return -code error "Only text/html documentation is currently supported"
    }

    set out "<h3>[ns_quotehtml [file tail $path]]</h3>"
    
    if { [nsv_exists api_library_doc $path] } {
        array set doc_elements [nsv_get api_library_doc $path]
        append out "<blockquote><p>\n"
        append out [lindex $doc_elements(main) 0]

        append out "<dl>\n"
        append out "<dt><b>Location:</b>\n<dd>[ns_quotehtml $path]\n"
        if { [info exists doc_elements(creation-date)] } {
            append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]\n"
        }
        if { [info exists doc_elements(author)] } {
            append out "<dt><b>Author[ad_decode [llength $doc_elements(author)] 1 "" "s"]:</b>\n"
            foreach author $doc_elements(author) {
                append out "<dd>[::apidoc::format_author $author]\n"
            }
        }
        if { [info exists doc_elements(cvs-id)] } {
            append out [subst {
                <dt><b>CVS Identification:</b>
                <dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code>
            }]
        }
        append out "</dl>\n"
        append out "</blockquote>\n"
    }

    return $out
}

ad_proc -public api_type_documentation {
    type
} {
    @return html fragment of the api docs.
} {
    array set doc_elements [nsv_get doc_type_doc $type]
    append out "<h3>$type</h3>\n"

    array set properties [nsv_get doc_type_properties $type]

    append out "<blockquote>[lindex $doc_elements(main) 0]

<dl>
<dt><b>Properties:</b>
<dd>
"

    array set property_doc [list]
    if { [info exists doc_elements(property)] } {
        foreach property $doc_elements(property) {
            if { [regexp {^([^ \t]+)[ \t](.+)$} $property "" name value] } {
                set property_doc($name) $value
            }
        }
    }

    foreach property [lsort [array names properties]] {
        set info $properties($property)
        set type [lindex $info 0]
        append out "<b>$property</b>"
        if { $type ne "onevalue" } {
            append out " ($type)"
        }
        if { [info exists property_doc($property)] } {
            append out " - $property_doc($property)"
        }
        if {$type eq "onerow"} {
            append out "<br>\n"
        } else {
            set columns [lindex $info 1]
            append out "<ul type=disc>\n"
            foreach column $columns {
                append out "<li><b>$column</b>"
                if { [info exists property_doc($property.$column)] } {
                    append out " - $property_doc($property.$column)"
                }
            }
            append out "</ul>\n"
        }
    }

    append out \
        [::apidoc::format_common_elements doc_elements] \
        "<dt><b>Location:</b><dd>$doc_elements(script)\n" \
        "</dl></blockquote>\n"

    return $out
}

ad_proc -public api_proc_documentation {
    {-format text/html}
    -script:boolean
    -source:boolean
    -xql:boolean
    -label
    {-first_line_tag <h3>}
    {-proc_type ""}
    proc_name
} {

    Generates formatted documentation for a procedure.

    @param format the type of documentation to generate. Currently, only
    <code>text/html</code> and <code>text/plain</code> are supported.
    @param script include information about what script this proc lives in?
    @param xql include the source code for the related xql files?
    @param source include the source code for the script?
    @param proc_name the name of the procedure for which to generate documentation.
    @param label the label printed for the proc in the header line
    @param first_line_tag tag for the markup of the first line
    @return the formatted documentation string.
    @error if the procedure is not defined.       
} {
    if { $format ne "text/html" && $format ne "text/plain" } {
        return -code error "Only text/html and text/plain documentation are currently supported"
    }
    array set doc_elements [nsv_get api_proc_doc $proc_name]
    array set flags $doc_elements(flags)
    array set default_values $doc_elements(default_values)

    if {![info exists label]} {
        if {[llength $proc_name] > 1 && [info commands ::xo::api] ne ""} {
            set label [::xo::api method_label $proc_name]
        } else {
            set label $proc_name
        }
    }
    if { $script_p } {
        set pretty_name [api_proc_pretty_name \
                             -include_debug_controls \
                             -proc_type $proc_type \
                             -label $label \
                             $proc_name]
    } else {
        set pretty_name [api_proc_pretty_name \
                             -include_debug_controls \
                             -link \
                             -proc_type $proc_type \
                             -label $label \
                             $proc_name]
    }
    if {[regexp {<([^ >]+)} $first_line_tag match tag]} {
        set end_tag "</$tag>"
    } else {
        set first_line_tag "<h3>"
        set end_tag "</h3>"
    }
    append out $first_line_tag$pretty_name$end_tag
    
    if {[regexp {^(.*) (inst)?proc (.*)$} $proc_name match cl prefix method]
        && [info commands ::xo::api] ne ""
    } {
        set xotclArgs 1
        set scope ""
        regexp {^(.+) (.+)$} $cl match scope cl
        if {$prefix eq ""} {
            set pretty_proc_name "[::xo::api object_link $scope $cl] $method"
        } else {
            set pretty_proc_name [subst {<i>&lt;instance of [::xo::api object_link $scope $cl]&gt;</i> $method}]
        }
    } else {
        set xotclArgs 0
        if {[info commands ::xo::api] ne "" && [::xo::api isclass "" [lindex $proc_name 1]]} {
            set name [lindex $proc_name 1]
            set pretty_proc_name "[$name info class] [::xo::api object_link {} $name]"
        } else {
            set pretty_proc_name $proc_name
        }
    }

    lappend command_line $pretty_proc_name
    foreach switch $doc_elements(switches) {
        if {$xotclArgs} {
            if {"boolean" in $flags($switch)} {
                set value "<i>on|off</i> "
            } elseif {"switch" in $flags($switch)} {
                set value ""
            } else {
                set value "</i>$switch</i> "
            }
            if {"required" in $flags($switch)} {
                lappend command_line "-$switch $value"
            } else {
                lappend command_line "\[ -$switch $value\]"
            }
        } else {
            if {"boolean" in $flags($switch)} {
                lappend command_line "\[ -$switch \]"
            } elseif {"required" in $flags($switch)} {
                lappend command_line "-$switch <i>$switch</i>"
            } else {
                lappend command_line "\[ -$switch <i>$switch</i> \]"
            }
        }
    }
    
    set counter 0
    foreach positional $doc_elements(positionals) {
        if { [info exists default_values($positional)] } {
            lappend command_line "\[ <i>$positional</i> \]"
        } else {
            lappend command_line "<i>$positional</i>"
        }
    }
    if { $doc_elements(varargs_p) } {
        lappend command_line "\[ <i>args</i>... \]"
    }
    append out [util_wrap_list $command_line]

    set intro_out ""
    if { $script_p } {
        append intro_out [subst {<p>Defined in 
            <a href="/api-doc/procs-file-view?path=[ns_urlencode $doc_elements(script)]">$doc_elements(script)</a>
            <p>}]
    }
    
    if { $doc_elements(deprecated_p) } {
        append intro_out "<b><i>Deprecated."
        if { $doc_elements(warn_p) } {
            append intro_out " Invoking this procedure generates a warning."
        }
        append intro_out "</i></b><p>\n"
    }

    set main [lindex $doc_elements(main) 0]
    if {$main ne ""} {
        append intro_out "<p>[lindex $doc_elements(main) 0]\n<p>\n"
    }

    #
    # Make first a quick check, and if it fails, double check details
    #
    set haveBlocks [expr {[llength $doc_elements(switches)] > 0
                          || [llength $doc_elements(positionals)] > 0}]
    if {$haveBlocks == 0} {
        foreach e {param option return error author creation-date change-log cvs-id see} {
            if {[info exists doc_elements($e)] && $doc_elements($e) ne ""} {
                set haveBlocks 1
                break
            }
        }
    }
  
    if {$haveBlocks} {
        set blocks_out "<dl>\n"

        if { [info exists doc_elements(param)] } {
            foreach param $doc_elements(param) {
                if { [regexp {^([^ \t\n]+)[ \t\n]+(.*)$} $param "" name value] } {
                    set params($name) $value
                }
            }
        }
    
        if { [llength $doc_elements(switches)] > 0 } {
            append blocks_out "<dt><b>Switches:</b></dt><dd><dl>\n"
            foreach switch $doc_elements(switches) {
                append blocks_out "<dt><b>-$switch</b>"
                if {"boolean" in $flags($switch)} {
                    append blocks_out " (boolean)"
                } 
                
                if { [info exists default_values($switch)]
                     && $default_values($switch) ne "" 
                 } {
                    append blocks_out " (defaults to <code>\"[ns_quotehtml $default_values($switch)]\"</code>)"
                } 
                
                if {"required" in $flags($switch)} {
                    append blocks_out " (required)"
                } else {
                    append blocks_out " (optional)"
                }
                append blocks_out "</dt>"
                if { [info exists params($switch)] } {
                    append blocks_out "<dd>$params($switch)</dd>"
                }
            }
            append blocks_out "</dl></dd>\n"
        }
        
        if { [llength $doc_elements(positionals)] > 0 } {
            append blocks_out "<dt><b>Parameters:</b></dt><dd>\n"
            foreach positional $doc_elements(positionals) {
                append blocks_out "<b>$positional</b>"
                if { [info exists default_values($positional)] } {
                    if { $default_values($positional) eq "" } {
                        append blocks_out " (optional)"
                    } else {
                        append blocks_out " (defaults to <code>\"$default_values($positional)\"</code>)"
                    }
                }
                if { [info exists params($positional)] } {
                    append blocks_out " - $params($positional)"
                }
                append blocks_out "<br>\n"
            }
            append blocks_out "</dd>\n"
        }
        

        # @option is used in  template:: and cms:: (and maybe should be used in some other 
        # things like ad_form which have internal arg parsers.  although an option 
        # and a switch are the same thing, just one is parsed in the proc itself rather than 
        # by ad_proc.

        if { [info exists doc_elements(option)] } {
            append blocks_out "<b>Options:</b><dl>"
            foreach param $doc_elements(option) {
                if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
                    append blocks_out "<dt><b>-$name</b></dt><dd>$value<br></dd>"
                }
            }
            append blocks_out "</dl>"
        }
        

        if { [info exists doc_elements(return)] } {
            append blocks_out "<dt><b>Returns:</b></dt><dd>[join $doc_elements(return) "<br>"]</dd>\n"
        }
    
        if { [info exists doc_elements(error)] } {
            append blocks_out "<dt><b>Error:</b></dt><dd>[join $doc_elements(error) "<br>"]</dd>\n"
        }

        append blocks_out [::apidoc::format_common_elements doc_elements]
        append blocks_out "</dl>\n"
    } else {
        set blocks_out ""
    }

    if { $source_p } {
        if {[parameter::get_from_package_key \
                 -package_key acs-api-browser \
                 -parameter FancySourceFormattingP \
                 -default 1]} {
            set source_out [subst {<dt><b>Source code:</b></dt><dd>
                <pre class="code">[::apidoc::tcl_to_html $proc_name]</pre>
                </dd>
            }]
        } else {
            set source_out [subst {<dt><b>Source code:</b></dt><dd>
                <pre class="code">[ns_quotehtml [api_get_body $proc_name]]</pre>
                </dd>
            }]
        }
    } else {
        set source_out ""
    }

    set xql_base_name $::acs::rootdir/
    append xql_base_name [file rootname $doc_elements(script)]
    if { $xql_p } {
        set there {}
        set missing {}
        set xql_fn [file rootname $doc_elements(script)].xql
        if { [file exists $::acs::rootdir/$xql_fn] } {
            set content [apidoc::get_xql_snippet -proc_name $proc_name -xql_file $xql_fn]
            if {$content ne ""} {set content "<pre class='code'>$content</pre>"}
            append there [subst {<dt><b>Generic XQL file:</b> </dt>
                <dd>$content
                <a href="[ns_quotehtml [export_vars -base content-page-view {{source_p 1} {path $xql_fn}}]]">$xql_fn</a>
                <p>
                </dd>

            }]
        } else {
            lappend missing Generic
        }
        set xql_fn [file rootname $doc_elements(script)]-postgresql.xql
        if { [file exists $::acs::rootdir/$xql_fn] } {
            set content [apidoc::get_xql_snippet -proc_name $proc_name -xql_file $xql_fn]
            if {$content ne ""} {set content "<pre class='code'>$content</pre>"}
            set href [export_vars -base content-page-view {{source_p 1} {path $xql_fn}}]
            append there [subst {<dt><b>PostgreSQL XQL file:</b></dt>
                <dd>$content
                <a href="[ns_quotehtml $href]">$xql_fn</a>
                <p>
                </dd>
            }]
        } else {
            lappend missing PostgreSQL
        }
        set xql_fn [file rootname $doc_elements(script)]-oracle.xql

        if { [file exists $::acs::rootdir/$xql_fn] } {
            set content [apidoc::get_xql_snippet -proc_name $proc_name -xql_file $xql_fn]
            if {$content ne ""} {set content "<pre class='code'>$content</pre>"}
            set href [export_vars -base content-page-view {{source_p 1} {path $xql_fn}}]
            append there [subst {<dt><b>Oracle XQL file:</b></dt>
                <dd>$content
                <a href="[ns_quotehtml $href]">$xql_fn</a>
                <p>
                </dd>
            }]
        } else {
            lappend missing Oracle
        }
        if {[llength $missing] > 0} { 
            set xql_out [subst {<dt><b>XQL Not present:</b></dt><dd>[join $missing ", "]</dd>}]
        }
        append xql_out $there  
    } else {
        set xql_out ""
    }

    set out_sections $intro_out$blocks_out$source_out$xql_out
    if {$out_sections ne ""} {
        append out <blockquote>$out_sections</blockquote>
    }
    # No "see also" yet.
    
    return $out
}

ad_proc api_proc_pretty_name { 
    -link:boolean
    -include_debug_controls:boolean
    {-proc_type ""}
    -label
    proc 
} {
    Return a pretty version of a proc name
    @param label the label printed for the proc in the header line
    @param link provide a link to the documentation pages
} {
    if {![info exists label]} {
        set label $proc
    }
    if { $link_p } {
        append out [subst {<a href="[ns_quotehtml [api_proc_url $proc]]">$label</a>}]
    } else {    
        append out $label
    }
    set doc_elements [nsv_get api_proc_doc $proc]
    set debug_html [expr {$include_debug_controls_p && [info commands ::xo::api] ne ""
                          ? [::xo::api debug_widget $proc] : ""}]
    set hints {}
    if {$proc_type ne ""} {lappend hints $proc_type}
    if {[dict exists $doc_elements protection]} {lappend hints [dict get $doc_elements protection]}
    if {[dict get $doc_elements deprecated_p]} {lappend hints deprecated}
    if {[llength $hints] > 0} {
        append out " ([join $hints {, }])"
    }
    append out $debug_html
    return $out
}

ad_proc -public api_apropos_functions { string } {
    Returns the functions in the system that contain string in their name 
    and have been defined using ad_proc.
} {
    set matches [list]
    foreach function [nsv_array names api_proc_doc] {
        if {[string match -nocase "*$string*" $function]} {
            array set doc_elements [nsv_get api_proc_doc $function]
            lappend matches [list $function $doc_elements(positionals)]
        }
    }
    return $matches
}

ad_proc -public api_describe_function { 
    { -format text/plain }
    proc 
} {
    Describes the functions in the system that contain string and that
    have been defined using ad_proc.  The description includes the
    documentation string, if any.
} {
    set matches [list]
    foreach function [nsv_array names api_proc_doc] {
        if {[string match -nocase $proc $function]} {
            array set doc_elements [nsv_get api_proc_doc $function]
            switch $format {
                text/plain {
                    lappend matches [ad_html_to_text -- [api_proc_documentation -script $function]]
                }
                default {
                    lappend matches [api_proc_documentation -script $function]
                }
            }                    
        }
    }
    switch $format {
        text/plain {
            set matches [join $matches "\n"]
        }
        default {
            set matches [join $matches "\n<p>\n"]
        }
    }
    return $matches
}


ad_proc -public api_get_body {proc_name} {
    This function returns the body of a Tcl proc or an xotcl method.
    @param proc_name the name spec of the proc
    @return body of the specified prox
} {
    if {[info commands ::xo::api] ne ""
        && [regexp {^(.*) (inst)?proc (.*)$} $proc_name match obj prefix method]} {
        if {[regexp {^(.*) (.*)$} $obj match thread obj]} {
            return [::xo::api get_method_source $thread $obj $prefix $method]
        } else {
            return [::xo::api get_method_source "" $obj $prefix $method]
        }
    } elseif {[info commands ::xo::api] ne ""
              && [regexp {^([^ ]+) (Class|Object) (.*)$} $proc_name . thread kind obj]} {
        return [::xo::api get_object_source $thread $obj]
    } elseif {[info commands ::xo::api] ne ""
              && [regexp {(Class|Object) (.*)$} $proc_name . kind obj]} {
        return [::xo::api get_object_source "" $obj]
    } elseif {[info procs $proc_name] ne ""} {
        return [info body $proc_name]
    } elseif {[info procs ::nsf::procs::$proc_name] ne ""} {
        return [::nx::Object info method body ::nsf::procs::$proc_name]
    } else {
        return "No such Tcl-proc '$proc_name'"
    }
}


namespace eval ::apidoc {

    ad_proc -private get_xql_snippet {-proc_name -xql_file} {
        @return matching xql snippet for specified proc_name
    } {
        set content [template::util::read_file $::acs::rootdir/$xql_file]

        # make parsable XML, replace "partialquery" by "fullquery"
        set prepared_content [db_qd_internal_prepare_queryfile_content $content]

        dom parse -simple $prepared_content doc
        $doc documentElement root
        set result ""
        foreach q [$root selectNodes //fullquery] {
            if {[string match "$proc_name.*" [$q getAttribute name]]} {
                append result [$q asXML -indent 4] \n
            }
        }
        set readable_xml [string map {&lt; < &gt; > &amp; &} [string trimright $result]]
        return [ns_quotehtml $readable_xml]
    }

    ad_proc -public format_see { see } {
        Takes the value in the argument "see" and possibly formats it
        into a link that will give the user more info about that
        resource

        @param see a string expected to comtain the resource to format
        @return the html string representing the resource
    } {
        #regsub -all {proc *} $see {} see
        set see [string trim $see]
        if {[nsv_exists api_proc_doc $see]} {
            set href [export_vars -base /api-doc/proc-view {{proc $see}}]
            return [subst {<a href="[ns_quotehtml $href]">$see</a>}]
        }
        if {[string match "/doc/*" $see]
            || [util_url_valid_p $see]} { 
            return [subst {<a href="[ns_quotehtml $see]">$see</a>}]
        }
        if {[file exists "$::acs::rootdir${see}"]} {
            set href [export_vars -base content-page-view {{source_p 1} {path $see}}]
            return [subst {<a href="[ns_quotehtml $href]">$see</a>}]
        }
        return ${see}
    }

    ad_proc -public format_author { author_string } {

        Extracts information about the author and formats it into an
        HTML string.

        @param author_string author information to format
        @return the formatted result
    } {
        if { [regexp {^[^ \n\r\t]+$} $author_string] 
             && [string first "@" $author_string] >= 0 
             && [string first ":" $author_string] < 0 } {
            return [subst {<a href="mailto:$author_string">$author_string</a>}]
        } elseif { [regexp {^([^\(\)]+)\s+\((.+)\)$} [string trim $author_string] {} name email] } {
            return "$name &lt;<a href=\"mailto:$email\">$email</a>&gt;"
        }
        return $author_string
    }

    ad_proc -private format_changelog_list { changelog } {
        Format the change log info
    } {
        append out "<dt><b>Changelog:</b>\n"
        foreach change $changelog {
            append out "<dd>[format_changelog_change $change]</dd>\n"
        }
        return $out
    }

    ad_proc -private format_changelog_change { change } {
        Formats the change log line: turns email addresses in parenthesis into links.
    } { 
        regsub {\(([^ \n\r\t]+@[^ \n\r\t]+\.[^ \n\r\t]+)\)} $change {(<a href="mailto:\1">\1</a>)} change
        return $change
    }

    ad_proc -private format_author_list { authors } {

        Generates an HTML-formatted list of authors 
        (including <code>&lt;dt&gt;</code> and
         <code>&lt;dd&gt;</code> tags).

        @param authors the list of author strings.
        @return the formatted list, or an empty string if there are no authors.

    } {
        if { [llength $authors] == 0 } {
            return ""
        }
        append out "<dt><b>Author[ad_decode [llength $authors] 1 "" "s"]:</b>\n"
        foreach author $authors {
            append out "<dd>[format_author $author]</dd>\n"
        }
        return $out
    }

    ad_proc -private format_common_elements { doc_elements_var } {
        upvar $doc_elements_var doc_elements

        set out ""

        if { [info exists doc_elements(author)] } {
            append out [format_author_list $doc_elements(author)]
        }
        if { [info exists doc_elements(creation-date)] } {
            append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]</dd>\n"
        }
        if { [info exists doc_elements(change-log)] } {
            append out [format_changelog_list $doc_elements(change-log)]
        }
        if { [info exists doc_elements(cvs-id)] } {
            append out "<dt><b>CVS ID:</b>\n<dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code></dd>\n"
        }
        if { [info exists doc_elements(see)] } {
            append out [format_see_list $doc_elements(see)]
        }

        return $out
    }

    ad_proc -private format_see_list { sees } { 
        Generate an HTML list of referenced procs and pages.
    } { 
        append out "<br><strong>See Also:</strong>\n<ul>"
        foreach see $sees { 
            append out "<li>[format_see $see]\n"
        }
        append out "</ul>\n"
        
        return $out
    }

    ad_proc -private first_sentence { string } {

        Returns the first sentence of a string.

    } {
        if { [regexp {^(.+?\.)\s} $string "" sentence] } {
            return $sentence
        }
        return $string
    }

    ad_proc -private set_public {
        version_id
        { public_p "" }
    } {
        
        Gets or sets the user's public/private preferences for a given
        package.

        @param version_id the version of the package
        @param public_p if empty, return the user's preferred setting or the default (1) 
        if no preference found. If not empty, set the user's preference to public_p
        @return public_p

    } {
        set public_property_name "api,package,$version_id,public_p"
        if { $public_p eq "" } {
            set public_p [ad_get_client_property acs-api-browser $public_property_name]
            if { $public_p eq "" } {
                set public_p 1
            }
        } else {
            ad_set_client_property acs-api-browser $public_property_name $public_p
        }
        return $public_p
    }

    ad_proc -private ad_sort_by_score_proc {l1 l2} {
        basically a -1,0,1 result comparing the second element of the
        list inputs then the first. (second is int)
    } {
        if {[lindex $l1 1] eq [lindex $l2 1]} {
            return [string compare [lindex $l1 0] [lindex $l2 0]]
        } else {
            if {[lindex $l1 1] > [lindex $l2 1]} {
                return -1
            } else {
                return 1
            }
        }
    }

    ad_proc -private ad_sort_by_second_string_proc {l1 l2} {
        basically a -1,0,1 result comparing the second element of the
        list inputs then the first (both strings)
    } {
        if {[lindex $l1 1] eq [lindex $l2 1]} {
            return [string compare [lindex $l1 0] [lindex $l2 0]]
        } else {
            return [string compare [lindex $l1 1] [lindex $l2 1]]
        }
    }

    ad_proc -private ad_sort_by_first_string_proc {l1 l2} {
        basically a -1,0,1 result comparing the second element of the
        list inputs then the first.  (both strings)
    } {
        if {[lindex $l1 0] eq [lindex $l2 0]} {
            return [string compare [lindex $l1 1] [lindex $l2 1]]
        } else {
            return [string compare [lindex $l1 0] [lindex $l2 0]]
        }
    }

    ad_proc -private ad_keywords_score {keywords string_to_search} {
        returns number of keywords found in string to search.  
        No additional score for repeats
    } {
        # turn keywords into space-separated things
        # replace one or more commads with a space
        regsub -all {,+} $keywords " " keywords
        
        set score 0
        foreach word $keywords {
            # turns out that "" is never found in a search, so we
            # don't really have to special case $word eq ""
            if {[string match -nocase "*$word*" $string_to_search]} {
                incr score
            }
        }
        return $score
    }

    ad_proc -private is_object {scope proc_name} {
        Checks, whether the specified argument is an xotcl object.
        Does not cause problems when xocl is not loaded.
        @return boolean value
    } {
        set result 0
        catch {set result [::xo::api isobject $scope $proc_name]}
        return $result
    }

    ad_proc -private tcl_to_html {proc_name} {

        Given a proc name, formats it as HTML, including highlighting syntax in
        various colors and creating hyperlinks to other proc definitions.<BR>
        The inspiration for this proc was the tcl2html script created by Jeff Hobbs.
        <p>
        Known Issues:
        <ol>
        <li> This proc will mistakenly highlight switch strings that look like commands as commands, etc.
        <li> There are many undocumented AOLserver commands including all of the commands added by modules.
        <li> When a proc inside a string has explicitly quoted arguments, they are not formatted.
        <li> regexp and regsub are hard to parse properly.  E.g. If we use the start option, and we quote its argument,
        and we have an ugly regexp, then this code might highlight it incorrectly.
        </ol>

        @author Jamie Rasmussen (jrasmuss@mle.ie)

        @param proc_name procedure to format in HTML

    } {

        if {[info commands ::xo::api] ne ""} {
            set scope [::xo::api scope_from_proc_index $proc_name]
        } else {
            set scope ""
        }

        set proc_namespace ""
        regexp {^(::)?(.*)::[^:]+$} $proc_name match colons proc_namespace

        return [tclcode_to_html -scope $scope -proc_namespace $proc_namespace [api_get_body $proc_name]]
    }


    # Returns length of a variable name
    proc length_var {data} {
        if {[regexp -indices {^\$\{[^\}]+\}} $data found]} {
            return [lindex $found 1]           
        } elseif {[regexp -indices {^\$[A-Za-z0-9_:]+(\([\$A-Za-z0-9_\-/]+\))?} $data found]} {
            return [lindex $found 1]
        }
        return 0
    }


    # Returns length of a command name
    proc length_proc {data} {
        if {[regexp -indices {^(::)?[A-Za-z][:A-Za-z0-9_@]+} $data found]} {
            return [lindex $found 1]
        }
        return 0
    }

    # Returns length of subexpression, from open to close quote inclusive
    proc length_string {data} {
        regexp -indices {[^\\]\"} $data match
        return [expr {[lindex $match 1]+1}]
    }

    # Returns length of subexpression, from open to close brace inclusive
    # Doesn't deal with unescaped braces in substrings
    proc length_braces {data} {
        set i 1
        for {set count 1} {1} {incr i} {
            if {[string index $data $i] eq "\\"} {
                incr i
            } elseif {[string index $data $i] eq "\{"} {
                incr count            
            } elseif {[string index $data $i] eq "\}"} {
                incr count -1
            }
            if {!$count} { break }
        }
        return [expr {$i+1}]
    }

    # Returns number of spaces until next subexpression
    proc length_spaces {data} {
        regexp -indices {\s+} $data match
        return [expr {[lindex $match 1]+1}]
    }

    # Returns length of a generic subexpression
    proc length_exp {data} {
        if {[string index $data 0] eq "\""} {
            return [length_string $data]
        } elseif {[string index $data 0] eq "\{"} {
            return [length_braces $data]
        } elseif {[string index $data 0] eq " "} {
            return [length_spaces $data]
        }
        if { [regexp -indices { } $data match] } {
            return [lindex $match 1]
        }
        return 0
    }

    # Calculate how much text we should ignore
    proc length_regexp {data} {
        set i 0
        set found_regexp 0
        set curchar [string index $data $i]
        while {$curchar ne "\$" && $curchar ne "\[" &&
               ($curchar ne "\{" || !$found_regexp)} {
            if {$curchar eq "\{"} {set found_regexp 1}
            if {[string range $data $i $i+5] eq "-start"} {
                incr i [length_exp [string range $data $i end]] ;# -start
                incr i [length_exp [string range $data $i end]] ;# spaces
                incr i [length_exp [string range $data $i end]] ;# expression - it could be a var
            }
            incr i [length_exp [string range $data $i end]]
            set curchar [string index $data $i]
        }
        return [expr {$i - 1}]
    }

    ad_proc -private search_on_webindex {-page -host -root -proc} {
        Search for a matching link in the page and return the absolute link if found
    } {
        set url ""
        if { [regexp "<a href= *\['\"\](\[^>\"'\]+)\[\"'\]\[^>\]*>$proc</a>" $page match relative_url] } {
            if {[string match "/*" $relative_url]} {
                set url $host$relative_url
            } else {
                set url $root$relative_url
            }
        }
        return $url
    }

    ad_proc -private get_doc_url {-cmd -index -root -host} {

        foreach i $index r $root {
            set result [util_memoize [list ::util::http::get -url $i]]
            set page   [dict get $result page]

            #
            # Since man pages contain often a summary of multiple commands, try
            # abbreviation in case the full name is not found (e.g. man page "nsv"
            # contains "nsv_array", "nsv_set" etc.)
            #
            set url ""
            for {set i [string length $cmd]} {$i > 1} {incr i -1} {
                set proc [string range $cmd 0 $i]
                set url [apidoc::search_on_webindex \
                             -page $page \
                             -root $r \
                             -host $host \
                             -proc $proc]
                if {$url ne ""} {
                    ns_log notice "=== cmd <$cmd> --> $url"
                    return $url
                }
            }
        }
        ns_log notice "=== cmd <$cmd> not found on <$index> root <$root> host <$host>"
        return ""
    }

    ad_proc -private pretty_token {kind token} {
        Encode the specified token in HTML
    } {
        return "<span class='$kind'>$token</span>"
    }

    ad_proc -public tclcode_to_html {{-scope ""} {-proc_namespace ""} script} {

        Given a script, this proc formats it as HTML, including highlighting syntax in
        various colors and creating hyperlinks to other proc definitions.<BR>
        The inspiration for this proc was the tcl2html script created by Jeff Hobbs.

        @param script script to be formated in HTML

    } {

        set namespace_provided_p [expr {$proc_namespace ne ""}]
        
        set script [string trimright $script]
        template::head::add_style -style $::apidoc::style

        # Keywords will be colored as other procs, but not hyperlinked
        # to api-doc pages.  Perhaps we should hyperlink them to the Tcl man pages?
        # else and elseif are be treated as special cases later

        if {[info commands ::xo::api] ne ""} {
            set XOTCL_KEYWORDS [list self my next]
            # Only command names are highlighted, otherwise we could add XOTcl method
            # names by [lsort -unique [concat [list self my next] ..
            # [::xotcl::Object info methods] [::xotcl::Class info methods] ]]
        } else {
            set XOTCL_KEYWORDS {}
        }

        set data [string map [list & "&amp;" < "&lt;" > "&gt;"] \n$script]

        set in_comment 0
        set in_quotes 0
        set proc_ok 1
        set l [string length $data]
        for {set i 0} {$i < $l} {incr i} {
            set char [string index $data $i]
            switch -- $char {

                "\\" {
                    append html [string range $data $i [incr i]]
                    # This might have been a backslash added to escape &, <, or >.
                    if {[regexp {^(amp;|lt;|gt;)} [string range $data $i end] match esc]} {
                        append html $esc
                        incr i [string length $esc]
                    }
                }

                "\$" {
                    if {$in_comment || [string index $data $i+1] eq " "} {
                        append html "\$"
                    } else {
                        set varl [length_var [string range $data $i end]]
                        append html [pretty_token var [string range $data $i $i+$varl]]
                        incr i $varl
                    }
                }

                "\"" {
                    if {$in_comment} {
                        append html \"
                    } elseif {$in_quotes} {
                        append html \" </span>
                        set in_quotes 0
                    } else {
                        append html "<span class='string'>" \"
                        set in_quotes 1
                        set proc_ok 0
                    }
                }

                "\#" {
                    set prevchar [string index $data $i-1]
                    if {$proc_ok && !$in_comment && [regexp {[\s;]} $prevchar]} {
                        set in_comment 1
                        set proc_ok 0
                        append html "<span class='comment'>"
                    }
                    append html "#"
                }

                "\n" {
                    set proc_ok 1
                    if {$in_quotes} {
                        set proc_ok 0
                    }
                    if {$in_comment} {
                        append html </span>
                    }
                    append html "\n"
                    set in_comment 0
                }

                "\{" -
                ";" {
                    if {!$in_quotes} {
                        set proc_ok 1
                    }
                    append html $char
                }

                "\}" {
                    append html "\}"
                    # Special case else and elseif
                    if {[regexp {^\}(\s*)(else|elseif)(\s*\{)} [string range $data $i end] match pre els post]} {

                        append html $pre [pretty_token keyword $els] $post
                        set proc_ok 1
                        incr i [expr {[string length $pre] + [string length $els] + [string length $post]}]
                    }
                }

                "\[" {
                    if {!$in_comment} {
                        set proc_ok 1
                    }
                    append html "\["
                }

                " " {
                    append html " "
                }
                
                default {
                    if {$proc_ok} {
                        set proc_ok 0
                        set procl [length_proc [string range $data $i end]]
                        set proc_name [string range $data $i $i+$procl]

                        if {$proc_name eq "ad_proc"} {
                            #
                            # Pretty print comment after ad_proc rather than trying to index keywords
                            #
                            set endPos [string first \n $data $i+1]
                            if {$endPos > -1} {
                                set line0 [string range $data $i $endPos]
                                set line [string trim $line0]
                                #
                                # Does the line end with a open brace?
                                #
                                if {[string index $line end] eq "\{"} {
                                    # Do we have a signature of an
                                    # ad_proc (ad_proc ?-options ...?
                                    # name args) before that?
                                    #
                                    # Note, that this handles just
                                    # single line ad-proc signatures,
                                    # not multi-line argument lists.
                                    
                                    set start [string range $line 0 end-1]
                                    set elements 3
                                    for {set idx 1} {[string index [lindex $start $idx] 0] eq "-"} {incr idx} {
                                        incr elements
                                    }
                                    
                                    if {[llength $start] == $elements} {
                                        #
                                        # Read next lines until brace is balanced.
                                        #
                                        set comment_start [expr {[string last "\{" $line] + $i}]
                                        set comment_end [expr {$comment_start + 1}]
                                        while {![info complete [string range $data $comment_start $comment_end]]
                                               && $comment_end < $l} {
                                            incr comment_end
                                        }
                                        if {$comment_end < $l} {
                                            ns_log notice "AD_PROC CAND COMM [string range $data $comment_start $comment_end]"
                                            set url ""
                                            append html \
                                                "<a href='/api-doc/proc-view?proc=ad_proc' title='ad_proc'>" \
                                                [pretty_token proc ad_proc] </a> \
                                                [string range $data $i+7 $comment_start] \
                                                "<span class='comment'>" \
                                                [string range $data $comment_start+1 $comment_end-1] \
                                                "</span>\}" 
                                            set i $comment_end
                                            continue
                                        }
                                    }
                                }
                            }
                        }
                        if {$proc_name eq "*" || $proc_name eq "@"} {
                            append html $proc_name
                        } elseif {$proc_name in $::apidoc::KEYWORDS ||
                            ([regexp {^::(.*)} $proc_name match had_colons] 
                             && $had_colons in $::apidoc::KEYWORDS)} {

                            set url "/api-doc/proc-view?proc=$proc_name"
                            append html "<a href='[ns_quotehtml $url]' title='Tcl command'>" \
                                [pretty_token keyword $proc_name] </a>

                            #append html [pretty_token keyword $proc_name]

                        } elseif {$proc_name in $XOTCL_KEYWORDS} {
                            append html [pretty_token keyword $proc_name]

                        } elseif {[string match "ns*" $proc_name]} {
                            set url "/api-doc/tcl-proc-view?tcl_proc=$proc_name"
                            append html "<a href='[ns_quotehtml $url]' title='[ns_info name] command'>" \
                                [pretty_token proc $proc_name] </a>

                        } elseif {[string match "*__arg_parser" $proc_name]} {
                            append html [pretty_token helper $proc_name]

                        } elseif {$proc_namespace ne "" 
                                  && [info commands ::${proc_namespace}::${proc_name}] ne ""}  {
                            
                            if {[is_object $scope ${proc_namespace}::${proc_name}]} {
                                set url [::xo::api object_url \
                                             -show_source 1 -show_methods 2 \
                                             $scope ::${proc_namespace}::${proc_name}]
                                append html "<a href='[ns_quotehtml $url]' title='XOTcl object'>" \
                                    [pretty_token object $proc_name] </a>
                            } else {
                                set url [api_proc_url ${proc_namespace}::${proc_name}]
                                append html "<a href='[ns_quotehtml $url]' title='API command'>" \
                                    [pretty_token proc $proc_name] </a>
                            }
                        } elseif {[info commands ::$proc_name] ne ""} {
                            set absolute_name [expr {[string match "::*" $proc_name]
                                                     ? $proc_name
                                                     : "::${proc_name}"}]
                            if {[is_object $scope $absolute_name]} {
                                set url [::xo::api object_url \
                                             -show_source 1 -show_methods 2 \
                                             $scope $absolute_name]
                                append html "<a href='[ns_quotehtml $url]' title='XOTcl object'>" \
                                    [pretty_token object $proc_name] </a>
                            } else {
                                set url [api_proc_url $proc_name]
                                append html "<a href='[ns_quotehtml $url]' title='API command'>" \
                                    [pretty_token proc $proc_name] </a>
                            }
                        } else {
                            append html $proc_name
                            set proc_ok 1
                        }
                        incr i $procl

                        if {$proc_name eq "namespace" && !$namespace_provided_p} {
                            set endPos [string first \n $data $i+1]
                            if {$endPos > -1} {
                                set line [string range $data $i+1 $endPos]
                                regexp {\s*eval\s+(::)?(\S+)\s+} $line . . proc_namespace
                            }
                        }

                        if {$proc_name eq "regexp" || $proc_name eq "regsub"} {
                            #
                            # Hack for nasty regexp stuff
                            #
                            set regexpl [length_regexp [string range $data $i end]]
                            append html [string range $data $i+1 $i+$regexpl]
                            incr i $regexpl
                        } elseif {$proc_name in {util_memoize util_memoize_seed}} {
                            #
                            # special cases for util_memoize
                            #
                            set reminder [string range $data $i+1 end]

                            if {[regexp {^(\s*\[\s*list)} $reminder _ list]} {
                                # util_memoize + list
                                append html " \[" [pretty_token keyword list]
                                incr i [string length $list] 
                                set proc_ok 1
                            } else {
                                # util_memoize without list
                                set proc_ok 1
                            }
                        }
                    } else {
                        append html $char
                        set proc_ok 0
                    }
                }
            }
        }

        # We added a linefeed at the beginning to simplify processing
        return [string range $html 1 end]
    }

    ad_proc -private xql_links_list { path } {
        
        Returns list of xql files related to Tcl script file
        @param path path and filename from $::acs::rootdir
        
    } {
        
        set linkList [list]
        set filename $::acs::rootdir/$path
        set path_dirname [file dirname $path]
        set file_dirname [file dirname $filename]
        set file_rootname [file rootname [file tail $filename]]
        regsub {(-oracle|-postgresql)$} $file_rootname {} file_rootname
        set files \
            [lsort -decreasing \
                 [glob -nocomplain \
                      -directory $file_dirname \
                      "${file_rootname}{,-}{,oracle,postgresql}.{adp,tcl,xql}" ]]
        
        foreach file $files {
            lappend linkList [list \
                                  filename $file \
                                  link "content-page-view?source_p=1&path=[ns_urlencode $path_dirname/[file tail $file]]" \
                                 ]
            
        }

        return $linkList
    }

    ad_proc -private sanitize_path { {-prefix packages} path } {
        
        Return a sanitized path. Cleans path from directory traversal
        attacks and checks, if someone tries to access content outside
        of the specified prefix.
        
        @return sanitized path
    } {
        set path [ns_normalizepath $path]
        if {![string match "/$prefix/*" $path]} {
            set filename "$::acs::rootdir/$path"
            ns_log notice [subst {INTRUDER ALERT:\n\nsomesone tried to snarf '$filename'!
                file exists: [file exists $filename] user_id: [ad_conn user_id] peer: [ad_conn peeraddr]
            }]

            set path $prefix/$path
        }

        return $path
    }
}



####################
#
# Linking to api-documentation
#
####################

#
# procs for linking to libraries, pages, etc, should go here too.
#

ad_proc api_proc_url { proc } {
    Returns the URL of the page that documents the given proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 14 July 2000
} {
    return "/api-doc/proc-view?proc=[ns_urlencode $proc]&source_p=1"
}

ad_proc api_proc_link { proc } {
    Returns a full HTML link to the documentation for the proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 14 July 2000
} {
    return "<a href=\"[ns_quotehtml [api_proc_url $proc]]\">$proc</a>"
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
