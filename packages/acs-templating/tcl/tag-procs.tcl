ad_library {
    Auxiliary Procs for Tag Handlers for the ArsDigita Templating System

    @author Karl Goldstein         (karlg@arsdigita.com)
    @author Stanislav Freidin      (sfreidin@arsdigita.com)
    @author Christian Brechbuehler (chrisitan@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


ad_proc -private template_tag_if_condition { chunk params condition_type } {

    set condition "$condition_type \{"

    # parse simplified conditional expression
    set args [template_tag_if_concat_params $params]

    if {[catch {

        while { 1 } { 

            # process the conditional expression
            template_tag_if_interp_expr

            # Stop when we run out of args 
            if { [llength $args] == 0 } { break }

            set conjunction [lindex $args 0]      

            switch $conjunction {
                
                and { append condition " && " }
                or { append condition " || " }

                default { 
                    error "Invalid conjunction <tt>$conjunction</tt> in 
                 $condition_type tag" 
                }
            }
            
            set args [lrange $args 1 end] 
        }

    } errorMsg]} {

        set condition "$condition_type \{ 1 "
        set chunk $errorMsg
    }

    append condition "\} \{"

    switch $condition_type {
        if     {template::adp_append_code $condition}
        elseif {template::adp_append_code $condition -nobreak}
    }

    # Done evaluating condition; evaluate body
    template::adp_compile_chunk $chunk

    # Add closing code
    template::adp_append_code "\}"
}

ad_proc -public template_tag_if_concat_params { params } {
    append all the tags together and then eval as a list to restore
    quotes
} {

    set size [ns_set size $params]

    for { set i 0 } { $i < $size } { incr i } {
        set key [ns_set key $params $i]
        set value [ns_set value $params $i]
        if {$key eq $value} {
            lappend tokens $key
        } else {
            lappend tokens "$key=$value"
        }
    }

    # LARS: The 'eval' statement here breaks if any key or value above contains a semicolon,
    # since this causes eval to treat whatever comes after the semicolon as a new command.
    # I'm not sure why we need to eval here at all, there ought to be another solution,
    # but it's not clear what the intention of below statement is.

    #set tokens [eval [concat list [join $tokens " "]]]
    set tokens [join $tokens " "]

    return $tokens
}

ad_proc -private template_tag_subst_reference {arg} {
    substitute variable references
    @return variable name 
} {
    if { [regsub {^"@([a-zA-Z0-9_]+)\.([a-zA-Z0-9_.-]+)@"$} $arg {\1(\2)} arg1] } {
    } elseif { [regsub {^"@([a-zA-Z0-9_:]+)@"$} $arg {\1} arg1] } { 
    } else {
        set arg1 ""
    }
    return $arg1
}


ad_proc -public template_tag_if_interp_expr {} {
    Interpret an expression as part of the simplified IF syntax
} {

    upvar args args condition condition

    # append condition "\[expr "

    set op [lindex $args 1]

    if { $op eq "not" } {
        #
        # Optimize common case "@arg@ not nil"
        #
        set op [lindex $args 2]
        set arg1 \"[lindex $args 0]\"
        if {$op eq "nil" && [string first @ $arg1] > -1} {
            set arg1 [template_tag_subst_reference $arg1]
            append condition "(\[info exists $arg1\] && \${$arg1} ne {})"
            set args [lrange $args 3 end]
            return
        } else {
            append condition "! ("
            set close_paren ")"
        }
        set i 3
    } else {
        set close_paren ""
        set i 2
    }

    set arg1 "\"[lindex $args 0]\""

    # build the conditional expression

    switch $op {

        gt { 
            append condition "$arg1 > \"[lindex $args $i]\"" 
            set next [expr {$i + 1}]
        }
        ge { 
            append condition "$arg1 >= \"[lindex $args $i]\"" 
            set next [expr {$i + 1}]
        }
        lt { 
            append condition "$arg1 <  \"[lindex $args $i]\"" 
            set next [expr {$i + 1}]
        }
        le { 
            append condition "$arg1 <= \"[lindex $args $i]\"" 
            set next [expr {$i + 1}]
        }
        eq { 
            append condition "$arg1 eq \"[lindex $args $i]\"" 
            set next [expr {$i + 1}]
        }
        ne { 
            append condition "$arg1 ne \"[lindex $args $i]\"" 
            set next [expr {$i + 1}]
        }

        in { 
            append condition "$arg1 in { [lrange $args 2 end] } "
            set next [llength $args]
        }

        between { 
            set expr1 "$arg1 >= \"[lindex $args $i]\""
            set expr2 "$arg1 <= \"[lindex $args $i+1]\""
            append condition "($expr1 && $expr2)" 
            set next [expr {$i + 2}]
        }

        nil {
            if { [string first @ $arg1] == -1 } {
                # We're assuming this is a static string, not a variable
                append condition "$arg1 eq {}"
            } else {
                set arg [template_tag_subst_reference $arg1]
                if {$arg eq ""} {
                    error "IF tag nil test uses string not variable for $arg1"
                }
                append condition "(!\[info exists $arg\] || \${$arg} eq {})"
            }
            set next $i
        }

        defined {
            set arg [template_tag_subst_reference $arg1]
            if {$arg eq ""} {
                error "IF tag nil test uses string not variable for $arg1"
            }
            append condition "\[info exists $arg\]"
            set next $i
        }

        odd { 
            append condition "\[expr {$arg1 % 2}\]" 
            set next $i
        }

        even { 
            append condition "! \[expr {$arg1 % 2}\]" 
            set next $i
        }
        
        true {
            #append condition "\[template::util::is_true $arg1\]"
            append condition "\[string is true -strict $arg1\]"
            set next $i
        }
        
        false {
            append condition "!\[template::util::is_true $arg1\]"
            set next $i
        }

        default { 
            # treat <if @foo_p@> as a shortcut for <if @foo_p@ true>
            #append condition "\[template::util::is_true $arg1\]"
            append condition "\[string is true -strict $arg1\]"
            set next [expr {$i - 1}]
        }
    }

    append condition $close_paren
    # append condition "]"

    set args [lrange $args $next end]
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

