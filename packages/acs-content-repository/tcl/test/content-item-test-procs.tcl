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

            aa_true "Folder created" [expr {$first_folder_id == $returned_first_folder_id}]

            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder is empty" [string is true $is_empty]

            #########################################################
            # create another cr_folder
            #########################################################

            set second_folder_id [db_nextval  "acs_object_id_seq"]
            set returned_second_folder_id [content::folder::new \
                                               -folder_id $second_folder_id \
                                               -name "test_folder_${second_folder_id}"]
            aa_true "Folder 2 created" [expr {$second_folder_id == $returned_second_folder_id}]


            #########################################################
            # create a cr_item
            #########################################################

            set test_name "cr_test_item[ad_generate_random_string]"
            set first_item_id [db_nextval  "acs_object_id_seq"]
            set returned_first_item_id [content::item::new \
                                            -name "$test_name" \
                                            -item_id $first_item_id \
                                            -parent_id $first_folder_id \
                                            -is_live "t" \
                                            -attributes [list [list title "$test_name"]]
                                       ]

            aa_true "First item created" [expr {$first_item_id == $returned_first_item_id}]

            aa_true "first item exists" [expr {[content::item::get -item_id $first_item_id] == 1}]

            aa_true "First item's revision exists" \
                [expr \
                     {![string equal "" \
                            [db_string get_revision {
                                select latest_revision from cr_items, cr_revisions
                                where latest_revision=revision_id and cr_items.item_id = :first_item_id
                            } -default ""]]}]

            # check the folder is not empty now.
            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder 1 is not empty" [string is false $is_empty]

            #########################################################
            # create a cr_item with evil string
            #########################################################
            
            set evil_string {-Bad [BAD] \077 \{ $Bad }
            set evil_test_name  "${evil_string}cr_test_item[ad_generate_random_string]"
            aa_log "evil_test_name is $evil_test_name"
            set evil_item_id [db_nextval  "acs_object_id_seq"]
            set returned_evil_item_id [content::item::new \
                                            -name "${evil_test_name}" \
                                            -item_id $evil_item_id \
                                            -parent_id $first_folder_id \
                                           -attributes [list [list title "${evil_test_name}"]]
                                       ]

            aa_true "Evil_name item created" [expr {$evil_item_id == $returned_evil_item_id}]

            aa_true "Evil_name item exists" [expr \
                                                 [content::item::get \
                                                      -item_id $evil_item_id \
                                                      -revision latest \
                                                      -array_name evil_name] == 1]
            aa_true "Evil_name item's revision exists" \
                [expr \
                     {$evil_name(latest_revision) ne ""}]

            #########################################################
            # delete the evil_name item
            #########################################################
            
            # in oracle content_item.del is not a function and cannot
            # return true or false so we have to rely on a query to
            # see if the item exists or not
            
            content::item::delete -item_id $evil_item_id
            array unset evil_name
            aa_true "evil_name item no longer exists" [expr \
                [content::item::get \
                     -item_id $evil_item_id \
                     -revision "latest" \
                     -array_name evil_name] == 0]
            aa_true "evil_name item revision does not exist" [expr \
                                                              ![info exists evil(latest_revision)]]


            #########################################################
            # create a new content type
            #########################################################

	    catch {content::type::delete -content_type "test_type"} errmsg
	    set new_type_id [content::type::new \
               -content_type "test_type" \
                -pretty_name "test_type" \
                -pretty_plural "test_type" \
                -table_name "test_type" \
                -id_column "test_id"]


            #########################################################
            # create an attribute
            #########################################################
            content::type::attribute::new \
                -content_type "test_type" \
                -attribute_name "attribute_name" \
                -datatype "text" \
                -pretty_name "Attribute Name" \
                -pretty_plural "Attribute Names" \
                -column_spec "text"
            
            # todo test that new item is NOT allowed to be created
            # unless registered by catching error when creating new
            # item
            
            #########################################################
            # register new type to folder
            #########################################################

            content::folder::register_content_type \
                -folder_id $first_folder_id \
                -content_type "test_type"
            # create an item of that type
            set new_type_item_id [db_nextval  "acs_object_id_seq"]
            set returned_new_type_item_id [content::item::new \
                                            -name "test_item_${new_type_item_id}" \
                                            -item_id $new_type_item_id \
                                            -parent_id $first_folder_id \
                                            -is_live "t" \
                                            -content_type  "test_type" \
                                               -attributes [list [list title "Title"] [list attribute_name "attribute_value"]]]

            #########################################################
            # check that the item exists
            #########################################################

            aa_true "New Type item created" [expr {$new_type_item_id == $returned_new_type_item_id}]
            aa_true "New Type item exists" [expr {[content::item::get \
                                                      -item_id $new_type_item_id \
                                                      -revision "latest" \
                                                      -array_name new_type_item] == 1}]

            #########################################################
            # check that extended attribute exists
            #########################################################
            aa_true "Extended attribute set" [expr [string equal "attribute_value" \
                               $new_type_item(attribute_name)]]

            #########################################################
            # test update of item and attributes
            #########################################################
            content::item::update \
                -item_id $new_type_item_id \
                -attributes {{name new_name} {publish_status live}}
            array unset new_type_item
            content::item::get \
                -item_id $new_type_item_id \
                -revision "latest" \
                -array_name new_type_item
            aa_true "Item updated $new_type_item(name) $new_type_item(publish_status)" [expr {($new_type_item(name)) eq "new_name" && ($new_type_item(publish_status) eq "live")} ]
            
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

            set new_name "__rename_new_name"
            content::item::rename \
                -item_id $new_type_item_id \
                -name $new_name
            content::item::get \
                -item_id $new_type_item_id \
                -array_name renamed_item
            aa_true "Item renamed" \
                [expr {$new_name eq $renamed_item(name)}]
                     

            #########################################################
            # publish it
            #########################################################
            #TODO

            #########################################################
            # unpublish it
            #########################################################
            #TODO


            #########################################################
            # new from tmpfile
            #########################################################            
            set tmp_item_name [ns_mktemp "__content_item_test_XXXXXX"] 
            set tmp_item_id [content::item::new \
                                 -name $tmp_item_name \
                                 -title $tmp_item_name \
                                 -parent_id $first_folder_id \
                                 -tmp_filename $::acs::rootdir/packages/acs-content-repository/tcl/test/test.html]

            aa_true "Tmp_filename added cr_item exists" \
                [expr {[content::item::get_id \
                            -item_path $tmp_item_name \
                            -root_folder_id $first_folder_id] \
                           eq $tmp_item_id}]

            aa_true "Tmp_filename added cr_revision exists" \
                [expr {[content::item::get_latest_revision \
                            -item_id $tmp_item_id] ne ""}]
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



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
