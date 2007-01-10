# 

ad_library {
    
    Tests for content keyword APIs
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-03-20
    @arch-tag: b66524da-fe12-4bd9-ae32-f635b0b3949b
    @cvs-id $Id$
}

aa_register_case content_keyword {
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
                [expr {$assigned_keyword_id == $keyword_id}]
            aa_true "Keyword heading set" \
                [string equal "--test_keyword" [content::keyword::get_heading -keyword_id $keyword_id]]
            aa_true "Keyword description set" \
                     [string equal "--test_description" [content::keyword::get_description -keyword_id $keyword_id]]
            # delete it
            content::keyword::delete -keyword_id $keyword_id
            aa_true "Keyword deleted" \
                [string equal [db_string confirm_delete "" -default ""] ""]
     }
}