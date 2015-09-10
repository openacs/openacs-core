ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case -cats {smoke api} acs_content_repository_trivial_smoke_test {
    Minimal smoke test.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # initialize random values
            set name [ad_generate_random_string]
            set name_2 [ad_generate_random_string]

            # there is no function in the api to directly retrieve a key
            # so instead we have to create a child of another and then
            # retrieve the parent's child

            set new_keyword_id [content::keyword::new -heading $name]
            aa_true "created a new content_keyword" [expr {[info exists new_keyword_id] && $new_keyword_id ne ""}]

            set new_keyword_id_2 [content::keyword::new -heading $name_2 -parent_id $new_keyword_id]
            aa_true "created a child content_keyword" [expr {[info exists new_keyword_id_2] && $new_keyword_id_2 ne ""}]

            set children [content::keyword::get_children -parent_id $new_keyword_id ]
            aa_true "child is returned" [string match "*$new_keyword_id_2*" $children]

            set delete_result [content::keyword::delete -keyword_id $new_keyword_id_2]

            set children_after_delete [content::keyword::get_children -parent_id $new_keyword_id ]
            aa_true "child is not returned after deletion" ![string match "*$new_keyword_id_2*" $children_after_delete]

            # teardown doesn't seem to eliminate this:
            set delete_result [content::keyword::delete -keyword_id $new_keyword_id]

            # would test that delete works but there's no relevant function in the API 
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
