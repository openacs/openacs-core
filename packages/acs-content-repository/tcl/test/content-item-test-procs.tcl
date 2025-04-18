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
        content::item::get_root_folder
        content::item::get_id
        content::item::get_latest_revision
        content::item::new
        content::item::rename
        content::item::copy
        content::item::update
        content::item::content_is_null
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

            #########################################################
            # create a cr_folder
            #########################################################
            set first_folder_label [ad_generate_random_string]
            set first_folder_id [db_nextval "acs_object_id_seq"]
            set returned_first_folder_id [content::folder::new \
                                              -folder_id $first_folder_id \
                                              -label $first_folder_label \
                                              -name "test_folder_${first_folder_id}"]

            set root_folder_id [content::item::get_root_folder -item_id $first_folder_id]
            aa_true "Folder $first_folder_id is distinct from root folder $root_folder_id" \
                {$root_folder_id != $first_folder_id}
            aa_true "Folder $root_folder_id is a root folder" \
                [content::folder::is_root -folder_id $root_folder_id]


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

            aa_equals "content_revision is latest" \
                [content::revision::is_latest -revision_id $item_info(revision_id)] \
                t
            aa_equals "content_revision is live" \
                [content::revision::is_live -revision_id $item_info(revision_id)] \
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

            aa_false "Item $index_item_id is not null" \
                [content::item::content_is_null [db_string rev {
                    select live_revision from cr_items
                    where item_id = :index_item_id
                }]]

            #########################################################
            # create an empty cr_item
            #########################################################

            set empty_item_id [content::item::new \
                                   -name emptyboi \
                                   -parent_id $first_folder_id \
                                   -is_live "t"]

            aa_false "Empty item $empty_item_id has no revision" \
                [db_0or1row rev {
                    select revision_id from cr_revisions
                    where item_id = :empty_item_id
                }]

            set empty_item_id [content::item::new \
                                   -name emptyboi2 \
                                   -parent_id $first_folder_id \
                                   -is_live "t" \
                                   -text "I will be empty"]

            aa_false "Empty item $empty_item_id is not null before emptying" \
                [content::item::content_is_null [db_string rev {
                    select live_revision from cr_items
                    where item_id = :empty_item_id
                }]]

            db_dml empty_the_boi {
                update cr_revisions set
                content = null
                where item_id = :empty_item_id
            }

            aa_true "Empty item $empty_item_id is now null" \
                [content::item::content_is_null [db_string rev {
                    select live_revision from cr_items
                    where item_id = :empty_item_id
                }]]

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
            unset evil_name
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
            unset new_type_item
            content::item::get \
                -item_id $new_type_item_id \
                -revision "latest" \
                -array_name new_type_item
            aa_true "Item updated $new_type_item(name) $new_type_item(publish_status)" \
                {$new_type_item(name) eq "new_name" && $new_type_item(publish_status) eq "live"}

            #########################################################
            # copy it
            #########################################################
            aa_equals "Item cannot be copied in the same folder using the same name" \
                [content::item::copy \
                     -item_id $new_type_item_id \
                     -target_folder_id $first_folder_id] ""

            aa_equals "Item cannot be copied in another folder without registering its content type first" \
                [content::item::copy \
                     -item_id $new_type_item_id \
                     -target_folder_id $second_folder_id] ""

            aa_log "Registering content type '$content_type' for '$second_folder_id'"
            content::folder::register_content_type \
                -folder_id $second_folder_id \
                -content_type $content_type

            set copied_no_sibling_item_id [content::item::copy \
                                                -item_id $new_type_item_id \
                                                -target_folder_id $second_folder_id]
            aa_true "Item can be copied in another folder using the same name after content type registration" \
                [string is integer -strict $copied_no_sibling_item_id]

            content::item::get \
                -item_id $copied_no_sibling_item_id \
                -array_name copied_no_sibling_item
            foreach att {name attribute_name} value {new_name attribute_value} {
                aa_equals "Copied item '$copied_no_sibling_item_id' has the right $att" \
                    $copied_no_sibling_item($att) $value
            }
            aa_equals "Copied item '$copied_no_sibling_item_id' has an empty title. This is expected" \
                $copied_no_sibling_item(title) ""


            aa_log "Cleanup the copy so we can test the no cascade cleanup later"
            content::item::delete -item_id $copied_no_sibling_item_id

            set copied_sibling_item_id [content::item::copy \
                                            -item_id $new_type_item_id \
                                            -target_folder_id $first_folder_id \
                                            -name copied_name]

            content::item::get \
                -item_id $copied_sibling_item_id \
                -array_name copied_sibling_item
            foreach att {name attribute_name} value {copied_name attribute_value} {
                aa_equals "Sibling copied item '$copied_sibling_item_id' has the right $att" \
                    $copied_sibling_item($att) $value
            }
            aa_equals "Sibling copied item '$copied_sibling_item_id' has an empty title. This is expected" \
                $copied_sibling_item(title) ""

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
            set tmp_item_name [ad_tmpnam "__content_item_test_XXXXXX"]
            set tmp_item_id [content::item::new \
                                 -name $tmp_item_name \
                                 -title $tmp_item_name \
                                 -parent_id $first_folder_id \
                                 -tmp_filename $::acs::rootdir/packages/acs-content-repository/tcl/test/test.html]

            aa_true "Item $tmp_item_id counts as null" \
                [content::item::content_is_null [db_string rev {
                    select live_revision from cr_items
                    where item_id = :tmp_item_id
                }]]

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

aa_register_case \
    -cats {api db} \
    -procs {
        ad_generate_random_string
        content::folder::new
        content::folder::is_folder
        content::item::new
        content::item::get_descendants
        content::item::get_path
        content::item::get_virtual_path
        content::item::get_publish_date
        content::item::get_publish_status
        content::item::unpublish
        content::item::get_root_folder
        content::item::is_published
        content::item::get_content
        content::item::get_revision_content
    } \
    content_item_nested_structure {
        Test API on a nested folder structure.
    } {

        aa_run_with_teardown \
            -rollback \
            -test_code {

                #########################################################
                # create the root folder of our test structure
                #########################################################
                set root_folder_id [db_nextval "acs_object_id_seq"]
                content::folder::new \
                    -folder_id $root_folder_id \
                    -name "test_folder_${root_folder_id}"

                content::folder::register_content_type \
                    -folder_id $root_folder_id \
                    -content_type "content_revision"

                content::folder::register_content_type \
                    -folder_id $root_folder_id \
                    -content_type "content_folder"

                #########################################################
                # create a cr_item in the root folder
                #########################################################

                set root_item_id [db_nextval "acs_object_id_seq"]
                content::item::new \
                    -name "test_item_$root_item_id" \
                    -item_id $root_item_id \
                    -parent_id $root_folder_id \
                    -is_live t \
                    -attributes [list [list title "test_item_$root_item_id"]]

                #########################################################
                # create a cr_folder
                #########################################################
                set first_folder_id [db_nextval "acs_object_id_seq"]
                content::folder::new \
                    -parent_id $root_folder_id \
                    -folder_id $first_folder_id \
                    -name "test_folder_${first_folder_id}"

                #########################################################
                # create a cr_item in the first toplevel folder
                #########################################################

                set first_item_id [db_nextval "acs_object_id_seq"]
                content::item::new \
                    -name "test_item_$first_item_id" \
                    -item_id $first_item_id \
                    -parent_id $first_folder_id \
                    -is_live t \
                    -attributes [list [list title "test_item_$first_item_id"]]

                #########################################################
                # create a subfolder
                #########################################################
                set sub_folder_id [db_nextval "acs_object_id_seq"]
                content::folder::new \
                    -parent_id $first_folder_id \
                    -folder_id $sub_folder_id \
                    -name "test_folder_${sub_folder_id}"

                #########################################################
                # create a cr_item in the subfolder
                #########################################################

                set sub_item_id [db_nextval "acs_object_id_seq"]
                content::item::new \
                    -name "test_item_$sub_item_id" \
                    -item_id $sub_item_id \
                    -parent_id $sub_folder_id \
                    -is_live t \
                    -mime_type text/plain \
                    -attributes [list [list title "test_item_$sub_item_id"]]


                #########################################################
                # create another toplevel folder
                #########################################################

                set second_folder_id [db_nextval "acs_object_id_seq"]
                content::folder::new \
                    -parent_id $root_folder_id \
                    -folder_id $second_folder_id \
                    -name "test_folder_${second_folder_id}"

                aa_section content::item::get_descendants

                aa_equals "Test descendants of root folder '$root_folder_id'" \
                    [lsort [content::item::get_descendants -parent_id $root_folder_id]] \
                    [lsort [list $root_item_id $first_item_id $first_folder_id $sub_folder_id $sub_item_id $second_folder_id]]

                aa_equals "Test descendants up to depth 1 of root folder '$root_folder_id'" \
                    [lsort [content::item::get_descendants -depth 1 -parent_id $root_folder_id]] \
                    [lsort [list $root_item_id $first_folder_id $second_folder_id]]

                aa_equals "Test descendants up to depth 2 of root folder '$root_folder_id'" \
                    [lsort [content::item::get_descendants -depth 2 -parent_id $root_folder_id]] \
                    [lsort [list $root_item_id $first_item_id $first_folder_id $sub_folder_id $second_folder_id]]

                aa_equals "Test descendants of folder '$first_folder_id'" \
                    [lsort [content::item::get_descendants -parent_id $first_folder_id]] \
                    [lsort [list $first_item_id $sub_folder_id $sub_item_id]]

                aa_equals "Test descendants up to depth 1 of folder '$first_folder_id'" \
                    [lsort [content::item::get_descendants -depth 1 -parent_id $first_folder_id]] \
                    [lsort [list $first_item_id $sub_folder_id]]

                aa_equals "Test descendants of folder '$second_folder_id'" "" ""


                aa_section content::item::get_path

                aa_equals "Test path of root folder '$root_folder_id'" \
                    [content::item::get_path -item_id $root_folder_id] \
                    /pages/test_folder_$root_folder_id

                aa_equals "Test path of item '$sub_item_id'" \
                    [content::item::get_path -item_id $sub_item_id] \
                    /pages/test_folder_$root_folder_id/test_folder_$first_folder_id/test_folder_$sub_folder_id/test_item_$sub_item_id

                aa_equals "Test path of item '$sub_item_id' starting from folder '$first_folder_id'" \
                    [content::item::get_path -item_id $sub_item_id -root_folder_id $first_folder_id] \
                    test_folder_$sub_folder_id/test_item_$sub_item_id

                aa_equals "Test path of item '$first_item_id'" \
                    [content::item::get_path -item_id $first_item_id] \
                    /pages/test_folder_$root_folder_id/test_folder_$first_folder_id/test_item_$first_item_id

                aa_section content::item::get_virtual_path

                #
                # Note: we are not testing symlinks so far, so
                # content::item::get_virtual_path will behave the same
                # as content::item::get_path.
                #

                aa_equals "Test path of root folder '$root_folder_id'" \
                    [content::item::get_virtual_path -item_id $root_folder_id] \
                    /pages/test_folder_$root_folder_id

                aa_equals "Test path of item '$sub_item_id'" \
                    [content::item::get_virtual_path -item_id $sub_item_id] \
                    /pages/test_folder_$root_folder_id/test_folder_$first_folder_id/test_folder_$sub_folder_id/test_item_$sub_item_id

                aa_equals "Test path of item '$sub_item_id' starting from folder '$first_folder_id'" \
                    [content::item::get_virtual_path -item_id $sub_item_id -root_folder_id $first_folder_id] \
                    test_folder_$sub_folder_id/test_item_$sub_item_id

                aa_equals "Test path of item '$first_item_id'" \
                    [content::item::get_virtual_path -item_id $first_item_id] \
                    /pages/test_folder_$root_folder_id/test_folder_$first_folder_id/test_item_$first_item_id


                aa_section content::item::get_publish_date

                set all_items [list $root_item_id $first_item_id $first_folder_id $sub_folder_id $sub_item_id $second_folder_id]
                foreach is_live {t f} {
                    foreach item_id $all_items {
                        set expected [db_string get_publish_date {
                            select r.publish_date
                              from cr_revisions r,
                                   cr_items i
                             where i.item_id = :item_id
                               and i.item_id = r.item_id
                               and ((:is_live = 't' and r.revision_id = i.live_revision) or
                                    (:is_live = 'f' and r.revision_id = i.latest_revision)
                                    )
                        } -default ""]
                        aa_equals "content::item::get_publish_date -item_id $item_id -is_live $is_live returns expected" \
                            [content::item::get_publish_date -item_id $item_id -is_live $is_live] \
                            $expected
                        aa_true "Empty publish date means the item is a folder (no revisions)" \
                            [expr {$expected ne "" || [content::folder::is_folder -item_id $item_id]}]
                    }
                }

                aa_section content::item::get_publish_status

                set all_items [list $root_item_id $first_item_id $first_folder_id $sub_folder_id $sub_item_id $second_folder_id]
                foreach item_id $all_items {
                    set expected [db_string get_publish_status {
                        select publish_status from cr_items where item_id = :item_id
                    }]
                    aa_equals "content::item::get_publish_status -item_id $item_id returns expected" \
                        [content::item::get_publish_status -item_id $item_id] \
                        $expected

                    foreach status {"production" "ready" "live" "expired"} {
                        aa_log "Set publish statut on '$item_id' to '$status'"
                        content::item::unpublish -item_id $item_id -publish_status $status

                        aa_equals "New publish status for '$item_id' is '$status'" \
                            [content::item::get_publish_status -item_id $item_id] \
                            $status

                        #
                        # To count as published, the item must have
                        # revisions (e.g. a folder cannot be
                        # published) and be in the 'live' status.
                        #
                        set is_published [expr {[content::item::is_published -item_id $item_id] ? 1 : 0}]
                        aa_true "Check if item '$item_id' counts as published" {
                            $is_published == ($status eq "live") ||
                            [content::folder::is_folder -item_id $item_id]
                        }
                    }
                }

                aa_section content::item::get_root_folder

                #
                # Note: what we call "root_folder" in out test setup
                # is the root of our test folder tree, not the cr root
                # folder that we fetch with this api!
                #
                set api_root_folder_id [content::item::get_root_folder -item_id $root_folder_id]
                set expected_root_folder_id [db_string get_root_folder {
                    select i2.item_id
                    from cr_items i1, cr_items i2
                    where i2.parent_id = -4
                    and i1.item_id = :root_folder_id
                    and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
                }]

                aa_equals "Root folder from api and query are the same" \
                    $api_root_folder_id $expected_root_folder_id

                foreach item_id $all_items {
                    aa_equals "Test item '$item_id' belongs to the same root folder as the others" \
                        $expected_root_folder_id [content::item::get_root_folder -item_id $item_id]
                }

                aa_section content::item::get_content

                content::item::get_content -item_id $sub_item_id -array content
                aa_true "Item '$sub_item_id' has a text mime type and the content array should contain the 'text' variable." \
                    [info exists content(text)]

            }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
