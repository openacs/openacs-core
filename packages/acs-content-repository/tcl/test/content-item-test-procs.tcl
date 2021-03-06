ad_library {

    Tests for content item

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28
    @cvs-id $Id$
}

aa_register_case \
    -cats {api db} \
    -procs {
        ad_generate_random_string
        content::folder::delete
        content::folder::get_index_page
        content::folder::get_label
        content::folder::is_empty
        content::folder::is_folder
        content::folder::is_registered
        content::folder::is_root
        content::folder::new
        content::folder::register_content_type
        content::item::delete
        content::item::get
        content::item::get_content_type
        content::item::get_id
        content::item::get_latest_revision
        content::item::new
        content::item::rename
        content::item::update
        content::revision::is_latest
        content::revision::is_live
        content::type::attribute::new
        content::type::delete
        content::type::new

        package_object_attribute_list
    } \
    content_item {
    content item test
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # <= 0 because it is -4 for Postgres and 0 for
            # Oracle... Here we assume every normal folder will have
            # something bigger than 0
            set root_folder_id [db_string get_root_folder {
                select min(item_id) from cr_items
                where content_type = 'content_folder'
                and parent_id <= 0
            }]
            aa_true "Folder $root_folder_id is a root folder" \
                [content::folder::is_root -folder_id $root_folder_id]

            #########################################################
            # create a cr_folder
            #########################################################
            set first_folder_label [ad_generate_random_string]
            set first_folder_id [db_nextval "acs_object_id_seq"]
            set returned_first_folder_id [content::folder::new \
                                              -folder_id $first_folder_id \
                                              -label $first_folder_label \
                                              -name "test_folder_${first_folder_id}"]

            aa_false "Folder $first_folder_id is not a root folder" \
                [content::folder::is_root -folder_id $first_folder_id]

            aa_false "'content_revision' is not registered on the folder" \
                [content::folder::is_registered \
                     -folder_id $first_folder_id \
                     -content_type content_revision]

            content::folder::register_content_type \
                -folder_id $first_folder_id \
                -content_type "content_revision"

            aa_true "'content_revision' is now registered on the folder" \
                [content::folder::is_registered \
                     -folder_id $first_folder_id \
                     -content_type content_revision]

            aa_true "Folder created" {$first_folder_id == $returned_first_folder_id}

            aa_true "Folder is a folder" [content::folder::is_folder -item_id $first_folder_id]

            aa_equals "Folder has the right label" \
                $first_folder_label [content::folder::get_label -folder_id $first_folder_id]

            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder is empty" [string is true $is_empty]

            #########################################################
            # create another cr_folder
            #########################################################

            set second_folder_id [db_nextval  "acs_object_id_seq"]
            set returned_second_folder_id [content::folder::new \
                                               -folder_id $second_folder_id \
                                               -name "test_folder_${second_folder_id}"]
            aa_true "Folder 2 created" {$second_folder_id == $returned_second_folder_id}


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

            aa_true "First item created" {$first_item_id == $returned_first_item_id}

            set content_type [content::item::get_content_type -item_id $first_item_id]
            aa_true "content_type is '$content_type'" {$content_type eq "content_revision"}

            aa_false "First item is not a folder" [content::folder::is_folder -item_id $first_item_id]

            aa_true "first item exists" {[content::item::get -item_id $first_item_id] == 1}

            content::item::get -item_id $first_item_id -array item_info
            set revision_id [dict get [array get item_info] revision_id]

            aa_equals "content_revision is latest" \
                [content::revision::is_latest -revision_id $revision_id] \
                t
            aa_equals "content_revision is live" \
                [content::revision::is_live -revision_id $revision_id] \
                t

            aa_true "First item's revision exists" \
                {[db_string get_revision {
                    select latest_revision from cr_items, cr_revisions
                    where latest_revision=revision_id and cr_items.item_id = :first_item_id
                } -default ""] ne ""}

            # check the folder is not empty now.
            set is_empty [content::folder::is_empty -folder_id $first_folder_id]
            aa_true "Folder 1 is not empty" [string is false $is_empty]

            #########################################################
            # create an index cr_item
            #########################################################

            set index_item_id [content::item::new \
                                   -name index \
                                   -parent_id $first_folder_id \
                                   -is_live "t" \
                                   -attributes [list [list title "$test_name"]]]

            aa_equals "Items $index_item_id is index in a folder $first_folder_id" \
                $index_item_id [content::folder::get_index_page -folder_id $first_folder_id]

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

            aa_true "Evil_name item created" {$evil_item_id == $returned_evil_item_id}

            aa_true "Evil_name item exists" {[content::item::get \
                                                  -item_id $evil_item_id \
                                                  -revision latest \
                                                  -array_name evil_name] == 1}
            aa_true "Evil_name item's revision exists" \
                {$evil_name(latest_revision) ne ""}

            #########################################################
            # delete the evil_name item
            #########################################################

            # in oracle content_item.del is not a function and cannot
            # return true or false so we have to rely on a query to
            # see if the item exists or not

            content::item::delete -item_id $evil_item_id
            array unset evil_name
            aa_true "evil_name item no longer exists" {
                [content::item::get \
                     -item_id $evil_item_id \
                     -revision "latest" \
                     -array_name evil_name] == 0}
            aa_true "evil_name item revision does not exist" {![info exists evil(latest_revision)]}


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

            aa_true "New Type item created" {$new_type_item_id == $returned_new_type_item_id}
            aa_true "New Type item exists" {[content::item::get \
                                                      -item_id $new_type_item_id \
                                                      -revision "latest" \
                                                      -array_name new_type_item] == 1}

            #########################################################
            # check that extended attribute exists
            #########################################################
            aa_equals "Extended attribute set" "attribute_value" $new_type_item(attribute_name)


            set content_type [content::item::get_content_type -item_id $new_type_item_id]
            aa_true "content_type is '$content_type" {$content_type eq "test_type"}

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
            aa_true "Item updated $new_type_item(name) $new_type_item(publish_status)" \
                {$new_type_item(name) eq "new_name" && $new_type_item(publish_status) eq "live"}

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
                {$new_name eq $renamed_item(name)}


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
                {[content::item::get_id \
                            -item_path $tmp_item_name \
                            -root_folder_id $first_folder_id] \
                           eq $tmp_item_id}

            aa_true "Tmp_filename added cr_revision exists" \
                {[content::item::get_latest_revision \
                            -item_id $tmp_item_id] ne ""}
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
