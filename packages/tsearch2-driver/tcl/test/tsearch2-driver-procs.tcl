ad_library {

    Tests for tsearch2-driver

    @author Dave Bauer (dave@thedesignexperience.org)
    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2005-03-07
    @cvs-id $Id$
}

ad_proc -private tsearch2::index_exists_p {
    object_id
} {
    Helper proc to check if an object is indexed
} {
    return [db_0or1row object_exists {
                select 1 from txt where object_id=:object_id
    }]
}

ad_proc -private tsearch2::indexed_keywords_p {
    -object_id
    -keywords
} {
    Helper proc to check if the keywords are indexed
} {
    if {[db_0or1row object_details {
            select fti from txt where object_id=:object_id
    }]} {
        set splitted_fti [split $fti ']
        foreach keyword $keywords {
            if {$keyword ni $splitted_fti} {
                aa_log "Keyword ($keyword) not found in fti: $fti"
                return false
            } else {
                aa_log "Keyword ($keyword) found"
            }
        }
        return true
    } else {
        return false
    }
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    tsearch2::build_query_tcl
} build_query_tcl {
    build_query_tcl test
} {
    aa_run_with_teardown -test_code {
        # some tests to see if we can turn the english query into
        # something tsearch2 to_tsquery can handle

        set q "openacs test automated"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Multiple terms automatic AND" \
            "$query" "openacs & test & automated"

        set q "openacs test not automated"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Multiple terms automatic AND, explicit NOT" \
            "$query" "openacs & test & ! automated"

        set q "openacs test or automated"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Multiple terms automatic AND, explicit OR" \
            "$query" "openacs & test | automated"

        set q "(openacs test) or automated"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Multiple terms grouped" \
            "$query" "(openacs & test) | automated"

        set q "(openacs or test) automated"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Multiple terms grouped automatic AND" \
            "$query" "(openacs | test) & automated"

        set q "one a two"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Single letter elements" "$query" "one & a & two"

        set q "or else"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Or at beginning by itself" "$query" "else"

        set q "not"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "Not all alone" "$query" ""

        set q "openacs and"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "AND at the end of the query" "$query" "openacs & and"

        set q "openacs or"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "OR at the end of the query" "$query" "openacs & or"

        set q "openacs and or"
        set query [tsearch2::build_query_tcl -query $q]
        aa_equals "AND and OR at the end of the query" "$query" "openacs & or"

    }
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    tsearch2::driver_info
} driver_info {
    Trivial test for driver_info
} {
    set expected_driver_info [list package_key tsearch2-driver \
                                   version 2 \
                                   automatic_and_queries_p 0 \
                                   stopwords_p 1]
    aa_equals "Driver info" [tsearch2::driver_info] $expected_driver_info
}

aa_register_case -cats {
    api
    production_safe
    smoke
} -procs {
    tsearch2::summary
} summary {
    Test tsearch2::summary
} {
    set query bold
    set txt "wow, this is bold"
    set expected "wow, this is <b>bold</b>"
    aa_equals "Summary" [tsearch2::summary $query $txt] $expected
}

aa_register_case -cats {
    api
} -procs {
    tsearch2::index
    tsearch2::unindex
    tsearch2::update_index
} index_unindex {
    Test indexing/unindexing
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Create test object
        #
        set object_id [package_instantiate_object acs_object]
        #
        # Check that index does not exist yet
        #
        aa_false "Index does not exist yet" \
            [tsearch2::index_exists_p $object_id]
        #
        # Index the object
        #
        set txt "This is just a test object"
        set title "Test object"
        set keywords "test foo bar"
        aa_log "Indexing object_id $object_id"
        tsearch2::index $object_id $txt $title $keywords
        #
        # Check if exists and looks ok
        #
        aa_true "Index exists"      [tsearch2::index_exists_p $object_id]
        aa_true "Index is correct"  [tsearch2::indexed_keywords_p \
                                        -object_id $object_id\
                                        -keywords $keywords]
        #
        # Update object
        #
        set txt "This is just a test object with edited text"
        set title "Test object updated"
        set keywords "test foo bar monger"
        tsearch2::update_index $object_id $txt $title $keywords
        #
        # Check if the keywords have been updated in the index
        #
        aa_true "Index is correct"  [tsearch2::indexed_keywords_p \
                                        -object_id $object_id\
                                        -keywords $keywords]
        #
        # Unindex object
        #
        aa_log "Unindexing object_id $object_id"
        tsearch2::unindex $object_id
        aa_false "Index does not exist anymore" \
            [tsearch2::index_exists_p $object_id]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
