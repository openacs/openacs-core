ad_library {
    
    Tests for content keyword APIs
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-03-20
    @cvs-id $Id$
}

aa_register_case \
    -cats {api db} \
    -procs {
        content::keyword::delete
        content::keyword::get_description
        content::keyword::get_heading
        content::keyword::new
    } \
    content_keyword {
        content_keyword test
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {

                # create a keyword
                set assigned_keyword_id [db_nextval "acs_object_id_seq"]
                set keyword_id [content::keyword::new \
                                    -heading "--test_keyword" \
                                    -description "--test_description" \
                                    -keyword_id $assigned_keyword_id]
                # check that keyword_id, heading, description
                # are set correctly
                aa_true "Keyword_id assigned" \
                    {$assigned_keyword_id == $keyword_id}
                aa_equals "Keyword heading set" \
                    [content::keyword::get_heading -keyword_id $keyword_id] "--test_keyword" 
                aa_equals "Keyword description set" \
                    [content::keyword::get_description -keyword_id $keyword_id] "--test_description" 
                # delete it
                content::keyword::delete -keyword_id $keyword_id
                aa_equals "Keyword deleted" [db_string confirm_delete "" -default ""] ""
            }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
