# 

ad_library {
    
    Tests for content item
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28
    @cvs-id $Id$
    
}

# FIXME DaveB Write some tests!

aa_register_case content_item {
    content item test
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # create a cr_folder
            set first_folder_id [db_nextval "acs_object_id_seq"]
            set returned_first_folder_id [content::folder::new \
                                              -folder_id $first_folder_id \
                                              -name "test_folder_${first_folder_id}"]

            content::folder::register_content_type \
                -folder_id $first_folder_id \
                -content_type "content_revision" 

            aa_true "Folder created" [expr $first_folder_id == $returned_first_folder_id]

            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder is empty" [string is true $is_empty]

            # create another
            set second_folder_id [db_nextval  "acs_object_id_seq"]
            set returned_second_folder_id [content::folder::new \
                                               -folder_id $second_folder_id \
                                               -name "test_folder_${second_folder_id}"]
            aa_true "Folder 2 created" [expr $second_folder_id == $returned_second_folder_id]
            # create a cr_item
            set first_item_id [db_nextval  "acs_object_id_seq"]
            set returned_first_item_id [content::item::new \
                                            -name "test_item_one" \
                                            -item_id $first_item_id \
                                            -parent_id $first_folder_id \
                                            -title "Title"
                                       ]

            aa_true "First item created" [expr $first_item_id == $returned_first_item_id]
            aa_true "First item exists" [expr $first_item_id == \
                                         [db_string get_item \
                                              "select item_id from
                                               cr_items where item_id=:first_item_id"]]
            aa_true "First item's revision exists" \
                [expr \
                     {![string equal "" \
                            [db_string get_revision "select
                                                     latest_revision
 from cr_items, cr_revisions where latest_revision=revision_id and cr_items.item_id=:first_item_id" -default ""]]}]

            # check the folder is not empty now.
            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder 1 is not empty" [string is false $is_empty]

            # copy it

            # move the copy

            # delete the copy

            # rename it

            # publish it

            # unpublish it

            # delete first folder and everything in it to clean up
            content::folder::delete \
                -folder_id $second_folder_id

            content::folder::delete \
                -folder_id $first_folder_id \
                -cascade_p "t"
        }

}


