ad_library {
    Procedures to test content::revision Tcl API

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    @cvs-id $Id$
}


aa_register_case \
    -cats {api db} \
    -procs {
        content::folder::delete
        content::folder::new
        content::folder::register_content_type
        content::folder::unregister_content_type
        content::item::delete
        content::item::get_content
        content::item::get_revision_count
        content::item::new
        content::revision::get_title
        content::revision::is_latest
        content::revision::is_live
        content::revision::item_id
        content::revision::new
        content::revision::revision_name
        cr_write_content
    } \
    content_revision {
        content revision test
    } {

    aa_run_with_teardown -rollback -test_code {

        # create a cr_folder
        set first_folder_id [db_nextval "acs_object_id_seq"]
        set returned_first_folder_id [content::folder::new \
                                          -folder_id $first_folder_id \
                                          -name "test_folder_${first_folder_id}"]
        aa_true "Folder created" \
            {$first_folder_id == $returned_first_folder_id}

        content::folder::register_content_type \
            -folder_id $first_folder_id \
            -content_type "content_revision" \

        # create a cr_item
        set first_item_id [db_nextval  "acs_object_id_seq"]
        set returned_first_item_id [content::item::new \
                                        -name "test_item_one" \
                                        -item_id $first_item_id \
                                        -parent_id $first_folder_id \
                                        -storage_type "text"]

        aa_true "First item created $first_item_id" \
            {$first_item_id == $returned_first_item_id}

        # create a revision
        set revision_id [db_nextval "acs_object_id_seq"]

        set title "Test Title"
        set returned_revision_id [content::revision::new \
                                      -revision_id $revision_id \
                                      -item_id $first_item_id \
                                      -title $title \
                                      -description "Test Description" \
                                      -content "Test Content"]
        aa_true "Basic Revision created revision_id $revision_id returned_revision_id $returned_revision_id " \
            {$revision_id == $returned_revision_id}

        content::item::get_content -revision_id $returned_revision_id -array revision_content
        set revision_content(content) [cr_write_content -revision_id $returned_revision_id -string]
        aa_true "Revision contains correct content" {
            $revision_content(title) eq $title
            && $revision_content(content) eq "Test Content"
            && $revision_id == $revision_content(revision_id)
        }

        aa_equals "content_revision is consistent" \
            [content::revision::item_id -revision_id $revision_id] \
            $first_item_id

        aa_equals "content_revision is latest" \
            [content::revision::is_latest -revision_id $revision_id] \
            t
        aa_equals "content_revision is live" \
            [content::revision::is_live -revision_id $revision_id] \
            f

        aa_equals "content_revision name" \
            [content::revision::revision_name -revision_id $revision_id] \
            "Revision 1 of 1 for item: Test Title"

        aa_equals "content_revision count for first item" \
            [content::item::get_revision_count -item_id $first_item_id] \
            1

        aa_equals "Title of the revision should be $title" \
            $title \
            [content::revision::get_title \
                       -revision_id $returned_revision_id]

        set revision_id2 [content::revision::new \
                              -item_id $first_item_id \
                              -title "rev2" \
                              -description "Test Description2" \
                              -content "Test Content2"]

        aa_equals "content_revision count for first item" \
            [content::item::get_revision_count -item_id $first_item_id] \
            2

        aa_equals "content_revision name" \
            [content::revision::revision_name -revision_id $revision_id2] \
            "Revision 2 of 2 for item: rev2"

        content::item::delete -item_id $first_item_id

        content::folder::unregister_content_type \
            -folder_id $first_folder_id \
            -content_type "content_revision" \

        content::folder::delete -folder_id $first_folder_id
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
