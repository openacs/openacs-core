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
	db_dml index "
            insert into txt (object_id,fti)
            values ( :object_id,
                     setweight(to_tsvector('default',coalesce(:title,'')),'A')
                   ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
                   ||to_tsvector('default',coalesce(:txt,'')))"
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
	db_dml update_index "
            update txt set fti =
                     setweight(to_tsvector('default',coalesce(:title,'')),'A')
                   ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
                   ||to_tsvector('default',coalesce(:txt,''))
            where object_id=:object_id
        "
    }
}

ad_proc -public tsearch2::search {
    query
    offset
    limit
    user_id
    df
    dt
} {
    
    ftsenginedriver search operation implementation for tsearch2
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05

    @param query

    @param offset

    @param limit

    @param user_id

    @param df

    @param dt

    @return

    @error
} {
    # clean up query
    # turn and into &
    # turn or into |
    # turn not into !
    set query [tsearch2::build_query -query $query]

    set limit_clause ""
    set offset_clause ""

    if {[string is integer $limit]} {
	set limit_clause " limit :limit "
    }
    if {[string is integer $offset]} {
	set offset_clause " offset :offset "
    }
    set query_text "select object_id from txt where fti @@ to_tsquery('default',:query) and exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = txt.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read') order by rank(fti,to_tsquery('default',:query)) desc  ${limit_clause} ${offset_clause}"
    set results_ids [db_list search $query_text]
    set count [db_string count "select count(*) from txt where fti @@ to_tsquery('default',:query)  and exists
                  (select 1 from acs_object_party_privilege_map m
                   where m.object_id = txt.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read')"]
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
   return [db_string summary "select headline('default',:txt,to_tsquery('default',:query))"]
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
    set p 0
    for {set i 0} {$i < [string length $query]} {incr i} {
	if {[string index $query $i] eq "("} {
	    incr p
	}
	if {[string index $query $i] eq ")"} {
	    incr p -1
	}
    }
    if {$p != 0} {
	regsub -all {\(|\)} $query {} query
    }

    # replace boolean words with boolean operators
    regsub -nocase "^not " $query {!} query
    set query [string map {" and " " & " " or " " | " " not " " ! "} " $query "]
    # remove leading and trailing spaces so they aren't turned into &
    set query [string trim $query]
    # remove any spaces between words and operators
    # all remaining spaces between words turn into &
    regsub -all {([-/@.\d\w\(\)])\s+?([-/@.\d\w\(\)])} $query {\1 \& \2} query
    # if a ! is by itself then prepend &
    regsub {(\w+?)\s*(!)} $query {\1 \& !} query
    # if there is )( then insert an & between them 
    # or if there is )\w or \w( insert an & between them
    regsub {(\))([\(\w])} $query {\1\ & \2} query
    regsub {([\)\w])(\()} $query {\1\ & \2} query
    return $query
}

ad_proc -public tsearch2::seperate_query_and_operators {
    -query
} {
    Seperates special operators from full text query
    
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
    if {[expr $quote_count % 2] == 1} {
	regsub -all {\"} $query {} query
    }

    set main_query ""
    set operators ""
    set last_operator ""
    set start_q 0
    set end_q 0
    set valid_operators [tsearch2_driver::valid_operators]
    foreach e [split $query] {
        ns_log notice "
DB --------------------------------------------------------------------------------
DB DAVE debugging procedure tsearch2::seperate_query_and_operators
DB --------------------------------------------------------------------------------
DB e = '${e}'
DB --------------------------------------------------------------------------------"
	if {[regexp {(^\w*):} $e discard operator] \
		&& [lsearch -exact $valid_operators $operator] != -1} {
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
	if {![string equal "" $last_operator]} {
	    # FIXME need introspection for operator phrase support
	    if {($last_operator eq "title:" || $last_operator eq "description:") && ($start_q || $end_q)} {
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
	if {[exists_and_not_null $op]} {
	    lappend operators $op $title
	}
    }
    lappend result $main_query
    if {![string equal "" $operators]} {
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