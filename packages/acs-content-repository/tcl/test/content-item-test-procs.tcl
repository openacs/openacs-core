# 

ad_library {
    
    Tests for content item
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28
    @cvs-id $Id$
    
}

aa_register_case content_item {
    content item test
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            #########################################################
            # create a cr_folder
            #########################################################
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

            #########################################################
            # create another cr_folder
            #########################################################

            set second_folder_id [db_nextval  "acs_object_id_seq"]
            set returned_second_folder_id [content::folder::new \
                                               -folder_id $second_folder_id \
                                               -name "test_folder_${second_folder_id}"]
            aa_true "Folder 2 created" [expr $second_folder_id == $returned_second_folder_id]


            #########################################################
            # create a cr_item
            #########################################################

            set test_name "cr_test_item[ad_generate_random_string]"
            set first_item_id [db_nextval  "acs_object_id_seq"]
            set returned_first_item_id [content::item::new \
                                            -name "$test_name" \
                                            -item_id $first_item_id \
                                            -parent_id $first_folder_id \
                                            -attributes [list title "$test_name"]
                                       ]

            aa_true "First item created" [expr $first_item_id == $returned_first_item_id]
            # should be using content::item::get here, but it's not implemented
            aa_true "First item exists" [expr $first_item_id == \
                                         [db_string get_item \
                                              "select item_id from
                                               cr_items where item_id=:first_item_id and name='$test_name'"]]
            aa_true "First item's revision exists" \
                [expr \
                     {![string equal "" \
                            [db_string get_revision "select
                                                     latest_revision
 from cr_items, cr_revisions where latest_revision=revision_id and cr_items.item_id=:first_item_id" -default ""]]}]

            # check the folder is not empty now.
            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder 1 is not empty" [string is false $is_empty]

            #########################################################
            # create a cr_item with bad string
            #########################################################
            
            set bad_string {-Bad [BAD] \077 \{ $Bad }
            set bad_test_name  "${bad_string}cr_test_item[ad_generate_random_string]"
            aa_log "bad_test_name is $bad_test_name"
            set bad_item_id [db_nextval  "acs_object_id_seq"]
            set returned_bad_item_id [content::item::new \
                                            -name "${bad_test_name}" \
                                            -item_id $bad_item_id \
                                            -parent_id $first_folder_id \
                                            -attributes [list title "${bad_test_name}"]
                                       ]

            aa_true "Bad_name item created" [expr $bad_item_id == $returned_bad_item_id]
            # should be using content::item::get here, but it's not implemented
            aa_true "Bad_name item exists" [expr $bad_item_id == \
                                         [db_string get_item \
                                              "select item_id from
                                               cr_items where item_id=:bad_item_id and name=:bad_test_name"]]
            aa_true "Bad_name item's revision exists" \
                [expr \
                     {![string equal "" \
                            [db_string get_revision "select
                                                     latest_revision
 from cr_items, cr_revisions where latest_revision=revision_id and cr_items.item_id=:bad_item_id" -default ""]]}]

            #########################################################
            # delete the bad_name item
            #########################################################
            

            aa_true "bad_name item deleted" [expr [content::item::delete -item_id $bad_item_id] == 0]

            # should be using content::item::get here, but it's not implemented
            aa_true "bad_name item no longer exists" [string equal \
              [db_string get_item "select item_id 
                                     from cr_items 
                                    where item_id=:bad_item_id 
                                      and name='$bad_test_name'" -default "no"] "no"]

            set bad_item_revision [db_string get_revision "select latest_revision
                                                             from cr_items, 
                                                                  cr_revisions 
                                                            where latest_revision=revision_id 
                                                              and cr_items.item_id=:bad_item_id" -default "no"]
            aa_true "bad_name item revision does not exist" [string equal $bad_item_revision "no"]


            #########################################################
            # create a new content type
            #########################################################
            set new_type_id [content::type::new \
               -content_type "__test_type" \
                -pretty_name "__test_type" \
                -pretty_plural "__test_type" \
                -table_name "__test_type" \
                -id_column "test_id"]

            # todo test that new item is NOT allowed to be created
            # unless registered by catching error when creating new
            # item
            
            #########################################################
            # register new type to folder
            #########################################################

            content::folder::register_content_type \
                -folder_id $first_folder_id \
                -content_type "__test_type"
            # create an item of that type
            set new_type_item_id [db_nextval  "acs_object_id_seq"]
            set returned_new_type_item_id [content::item::new \
                                            -name "test_item_${new_type_item_id}" \
                                            -item_id $new_type_item_id \
                                            -parent_id $first_folder_id \
                                            -content_type  "__test_type" \
                                               -attributes [list title "Title"]]

            #########################################################
            # check that the item exists
            #########################################################

            aa_true "New Type item created" [expr $new_type_item_id == $returned_new_type_item_id]
            aa_true "New Type item exists" [expr $new_type_item_id == \
                                         [db_string get_item \
                                              "select item_id from
                                               cr_items where item_id=:new_type_item_id and name='test_item_${new_type_item_id}'" -default ""]]

            #########################################################
            # check that the extended attributes and the revision
            # exist
            #########################################################
            aa_true "First item's revision exists" \
                [expr \
                     {![string equal "" \
                            [db_string get_revision "select
                                                     latest_revision
 from cr_items, __test_typex where latest_revision=test_id and cr_items.item_id=:new_type_item_id" -default ""]]}]
            
            


            #########################################################
            # copy it
            #########################################################
            #TODO
            
            #########################################################
            # move the copy
            #########################################################
            #TODO

            #########################################################
            # delete the item
            #########################################################
            #TODO

            #########################################################
            # rename it
            #########################################################
            #TODO

            #########################################################
            # publish it
            #########################################################
            #TODO

            #########################################################
            # unpublish it
            #########################################################
            #TODO

            #########################################################
            # delete first folder and everything in it to clean up
            #########################################################
            content::folder::delete \
                -folder_id $second_folder_id

            content::folder::delete \
                -folder_id $first_folder_id \
                -cascade_p "t"
        }

}


