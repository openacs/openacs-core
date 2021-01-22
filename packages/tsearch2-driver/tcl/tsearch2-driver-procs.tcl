ad_library {
    Procedures for tsearch full text enginge driver

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    @arch-tag: 49a5102d-7c06-4245-8b8d-15a3b12a8cc5
    @cvs-id $Id$
}

namespace eval tsearch2 {}

ad_proc -public tsearch2::index {
    object_id
    txt
    title
    keywords
} {
    add object to full text index

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param object_id
    @param txt
    @param title
    @param keywords

    @return nothing
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
      set max_size_to_index [db_string get_max_size_to_index "select min(default_value) from apm_parameters where package_key = 'tsearch2-driver' and parameter_name = 'max_size_to_index'" -default "0"]
      if {$max_size_to_index > 0} {
        set txt [string range $txt 0 $max_size_to_index]
      }
      db_dml index {}
    } else {
        tsearch2::update_index $object_id $txt $title $keywords
    }
}

ad_proc -public tsearch2::unindex {
    object_id
} {
    Remove item from FTS index

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param object_id

    @return nothing
} {
    db_dml unindex "delete from txt where object_id=:object_id"
}

ad_proc -public tsearch2::update_index {
    object_id
    txt
    title
    keywords
} {
    update full text index

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param object_id
    @param txt
    @param title
    @param keywords

    @return nothing
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
        tsearch2::index $object_id $txt $title $keywords
    } else {
      set max_size_to_index [db_string get_max_size_to_index "select min(default_value) from apm_parameters where package_key = 'tsearch2-driver' and parameter_name = 'max_size_to_index'" -default "0"]
      if {$max_size_to_index > 0} {
        set txt [string range $txt 0 $max_size_to_index]
      }
        db_dml update_index ""
    }
}

#ad_proc -callback search::search -impl tsearch2-driver {
#    {-extra_args {}}
#    query
#    offset
#    limit
#    user_id
#    df
#} 
ad_proc -callback search::search -impl tsearch2-driver {
    {-extra_args {}}
    -query
    -offset
    -limit
    -user_id
    -df
} {
    ftsenginedriver search operation implementation for tsearch2

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param query
    @param offset
    @param limit
    @param user_id
    @param df
    @param packages list of packages to search for content in.

    @return
    @error
} {
    set packages {}
    # JCD: I have done something horrible.  I took out dt and 
    # made it packages.  when you search there is no way to specify a date range just
    # last six months, last year etc.  I hijack what was the old dt param and make it 
    # the package_id list and just empty string for dt.
    set dt {}

    set orig_query $query

    # clean up query for tsearch2
    set query [tsearch2::build_query -query $query]

    set where_clauses ""
    set from_clauses ""
    if {![info exists user_id]} {set user_id 0}

    # don't use bind vars since pg7.3 yacks for '1' (which is what comes out of bind vars)
    set limit_clause ""
    set offset_clause ""
    if {[string is integer -strict $limit]} {
        set limit_clause " limit $limit "
    }
    if {[string is integer -strict $offset]} {
        set offset_clause " offset $offset "
    }

    set need_acs_objects 0
    set base_query [db_map base_query]
    if {$df ne ""} {
        set need_acs_objects 1
        lappend where_clauses "o.creation_date > :df"
    }
    if {$dt ne ""} {
        set need_acs_objects 1
        lappend where_clauses "o.creation_date < :dt"
    }

    foreach {arg value} $extra_args {
	array set arg_clauses [lindex [callback -impl $arg search::extra_arg -value $value -object_table_alias "o"] 0]
	if {[info exists arg_clauses(from_clause)] && $arg_clauses(from_clause) ne ""} {
	    lappend from_clauses $arg_clauses(from_clause)
	}
	if {[info exists arg_clauses(where_clause)] && $arg_clauses(where_clause) ne ""} {
	    lappend where_clauses $arg_clauses(where_clause)
	}
    }
    if {[llength $extra_args]} {
        # extra_args can assume a join on acs_objects
        set need_acs_objects 1
    }
    # generate the package id restriction.
    set ids {}
    foreach id $packages {
        if {[string is integer -strict $id]} {
            lappend ids $id
        }
    }
    if {$ids ne ""} {
        set need_acs_objects 1
        lappend where_clauses "o.package_id in ([join $ids ,])"
    }
    if {$need_acs_objects} {
        lappend from_clauses "txt" "acs_objects o"
        lappend where_clauses "o.object_id = txt.object_id"
    } else {
        lappend from_clauses "txt"
    }
    
    set results_ids [db_list search {}]

    set count [db_string count {}]

    set stop_words [list]

    # lovely the search package requires count to be returned but the
    # service contract definition doesn't specify it!
    return [list ids $results_ids stopwords $stop_words count $count]
}

ad_proc -public tsearch2::summary {
    query
    txt
} {
    Highlights matching terms.

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param query
    @param txt

    @return summary containing search query terms
    @error
} {
    set query [tsearch2::build_query -query $query]
    return [db_string summary {}]
}

ad_proc -callback search::driver_info -impl tsearch2-driver {
} {
    Search driver info callback
} {
    return [tsearch2::driver_info]
}

ad_proc -public tsearch2::driver_info {
} {
   
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @return 
    
    @error 
} {
    return [list package_key tsearch2-driver version 2 automatic_and_queries_p 0  stopwords_p 1]
}

ad_proc tsearch2::build_query { -query } {
    Convert conjunctions to query characters for tsearch2
    and => &
    not => !
    or => |
    space => | (or)
    
    @param string string to convert
    @return returns formatted query string for tsearch2 tsquery
} {
    # get rid of everything that isn't valid in a query
    # letters, numbers, @ . - ( ) are all valid
    regsub -all {[^-/@.\d\w\s\(\)]+} $query { } query

    # match parens, if they don't match just throw them away
    # set p 0
    # for {set i 0} {$i < [string length $query]} {incr i} {
    #     if {[string index $query $i] eq "("} {
    #         incr p
    #     }
    #     if {[string index $query $i] eq ")"} {
    #         incr p -1
    #     }
    # }
    # if {$p != 0} {
    #     regsub -all {\(|\)} $query {} query
    # }

    # remove all parens
    regsub -all {\(|\)} $query {} query

    # remove empty ()
    regsub -all {\(\s*\)} $query {} query

    # remove "or" at beginning of query 
    regsub -nocase "^or " $query {} query

    # remove "not" at end of query 
    regsub -nocase " not$" $query {} query

    # replace boolean words with boolean operators
    regsub -nocase "^not " $query {!} query
    set query [string map {" and " " & " " or " " | " " not " " ! "} " $query "]

    # remove leading and trailing spaces so they aren't turned into &
    set query [string trim $query]

    # remove any spaces between words and operators
    # all remaining spaces between words turn into &
    while {[regexp {([-/@.\d\w\(\)])\s+?([-/@.\d\w\(\)])} $query]} {
        regsub {([-/@.\d\w\(\)])\s+?([-/@.\d\w\(\)])} $query {\1 \& \2} query
    }
    # if a ! is by itself then prepend &
    regsub -all {(\w+?)\s*(!)} $query {\1 \& !} query
    # if there is )( then insert an & between them 
    # or if there is )\w or \w( insert an & between them
    regsub {(\))([\(\w])} $query {\1 \& \2} query
    regsub {([\)\w])(\()} $query {\1 \& \2} query
    if {[regsub {!|\||\&} $query {}] eq ""} {
        set query ""
    }
    return $query
}

ad_proc -public tsearch2::separate_query_and_operators {
    -query
} {
    Separates special operators from full text query
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-07-10
    
    @param query

    @return list of query and operators
    
    @error 
} {
    # remove evil characters
    regsub {\[|\]|\{|\}} $query {} query
    
    # match quotes
    set quote_count [regexp -all {\"} $query]
    # if quotes don't match, just remove all of them
    if {$quote_count % 2 == 1} {
        regsub -all {\"} $query {} query
    }

    set main_query ""
    set operators ""
    set last_operator ""
    set start_q 0
    set end_q 0
    set valid_operators [tsearch2_driver::valid_operators]
    foreach e [split $query] {
        if {[regexp {(^\w*):} $e discard operator]
	    && $operator in $valid_operators
        } {
            # query element contains an operator, split operator from
            # query fragment
            set e [split $e ":"]
            set e [list $operator [lindex $e 1]]
        }
        # count quotes to see if this element
        # is part of a phrase
        if {$start_q ne 1} {
            set start_q [regexp {^\"} $e]
        }
        set end_q [regexp {\"$} $e]

        if {$start_q} {
            set sq {"}
        } else {
            set sq {}
        }                        
        if {$end_q} {
            set start_q 0
            set eq {"}
        } else {
            set eq {}
        } 

        # now that we know if its parts of a phrase, get rid of the
        # quotes
        regsub -all {\"} $e {} e
        
        if {[llength $e] > 1} {
            # query element contains a valid operator
            set last_operator [lindex $e 0]
            set e [lindex $e 1]
        } else {
            set last_operator ""
        }
        # regular search term
        ns_log debug "operator(e)='${e}' start_q=$start_q end_q=$end_q"
        if {$last_operator ne ""} {
            # FIXME need introspection for operator phrase support
            if {
		($last_operator eq "title:" || $last_operator eq "description:") 
		&& ($start_q || $end_q)
	    } {
                lappend ${last_operator}_phrase [regsub -all {\"} $e {}]
            } else {
                lappend $last_operator [regsub -all {\"} ${e} {}]
            }
        } else {
            if {$start_q || $end_q} {
                lappend phrase $e
            } else {
                lappend main_query $e
            }
        }
    }

    foreach op $valid_operators {
        if {([info exists $op] && [set $op] ne "")} {
            lappend operators $op $title
        }
    }
    lappend result $main_query
    if {$operators ne ""} {
        lappend result $operators
    }
    return $result
}

ad_proc -private tsearch2_driver::valid_operators {
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-03-06
    
    @return list of advanced operator names
    
    @error 
} {
    return {title description package_id parent_id}
}
