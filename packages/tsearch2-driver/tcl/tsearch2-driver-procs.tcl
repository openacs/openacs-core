# 

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
    
    @return 
    
    @error 
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
	db_dml index "insert into txt (object_id,fti) values ( :object_id, to_tsvector('default',:txt))"

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

    @return 
    
    @error 
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
    
    @return 
    
    @error 
} {
    set index_exists_p [db_0or1row object_exists "select 1 from txt where object_id=:object_id"]
    if {!$index_exists_p} {
	db_dml index "insert into txt (object_id,fti) values ( :object_id, to_tsvector('default',:txt))"
    } else {
	db_dml update_index "update txt set fti = to_tsvector('default',:txt) where object_id=:object_id"
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
    set query_text "select object_id from txt where fti @@ to_tsquery('default',:query) and exists (select 1 from                    from acs_object_party_privilege_map m
                   where m.object_id = txt.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read')order by rank(fti,to_tsquery('default',:query))  ${limit_clause} ${offset_clause}"
    set results_ids [db_list search $query_text]
    set count [db_string count "select count(*) from txt where fti @@ to_tsquery('default',:query)"]
    set stop_words [list]
    # lovely the search package requires count to be returned but the
    # service contract definition doesn't specify it! 
    return [list ids $results_ids stopwords $stop_words count $count]
}

ad_proc -public tsearch2::summary {
    query
    txt
} {
    
    
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
    # get rid of everything that isn't a letter or number
    regsub -all {[^?\d\w\s]} $query {} query

    # replace boolean words with boolean operators
    set query [string map {" and " & " or " | " not " !} $query]
    # remove leading and trailing spaces so they aren't turned into |
    set query [string trim $query]
    # remove any spaces between words and operators
    regsub -all {\s+([!&|])\s+} $query {\1} query
    # all remaining spaces between words turn into |
    regsub -all {\s+} $query {\&} query
    # if a ! is by itself then prepend &
    regsub {(\w)([!])} $query {\1\&!} query

    return $query
}
