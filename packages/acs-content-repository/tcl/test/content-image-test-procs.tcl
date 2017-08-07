ad_library {
    Procedures to test content::image Tcl API

    @author Hugh Brock
    @creation-date 2006-01-17
    @cvs-id $Id$
}


aa_register_case content_image {
    content image test
} {

    aa_run_with_teardown -rollback -test_code {

        # create a cr_folder
        set first_folder_id [db_nextval "acs_object_id_seq"]
        set returned_first_folder_id [content::folder::new \
                                          -folder_id $first_folder_id \
                                          -name "test_folder_${first_folder_id}"]
        aa_true "Folder created" \
            [expr {$first_folder_id == $returned_first_folder_id}]

        content::folder::register_content_type \
            -folder_id $first_folder_id \
            -content_type "image" \

        # create a cr_item
        set first_item_id [db_nextval  "acs_object_id_seq"]
        set returned_first_item_id [content::item::new \
                                        -name "test_item_one" \
                                        -item_id $first_item_id \
                                        -parent_id $first_folder_id \
                                        -content_type "image" \
                                        -storage_type "file"]

        aa_true "First item created $first_item_id" \
            [expr {$first_item_id == $returned_first_item_id}]

        # create an image
        set image_id [db_nextval "acs_object_id_seq"]

        set returned_image_id [content::revision::new \
                                   -revision_id $image_id \
                                   -item_id $first_item_id \
                                   -title "Test Title" \
                                   -description "Test Description"]
        aa_true "Basic Image created revision_id $image_id returned_revision_id $returned_image_id " \
            [expr {$image_id == $returned_image_id}]

        ::content::item::get_content -revision_id $returned_image_id -array revision_content
        aa_true "Revision contains correct content" \
            [expr {$revision_content(title) eq "Test Title"
                   && $image_id == $revision_content(revision_id)}]

        content::item::delete -item_id $first_item_id

        content::folder::unregister_content_type \
            -folder_id $first_folder_id \
            -content_type "image" \

        content::folder::delete -folder_id $first_folder_id
    }
}

aa_register_case -cats {api smoke db} image_new {

} {
    aa_run_with_teardown -rollback -test_code {
        # create a cr_folder
        set first_folder_id [db_nextval "acs_object_id_seq"]
        set returned_first_folder_id [content::folder::new \
                                          -folder_id $first_folder_id \
                                          -name "test_folder_${first_folder_id}"]
        aa_true "Folder created" \
            [expr {$first_folder_id == $returned_first_folder_id}]

        content::folder::register_content_type \
            -folder_id $first_folder_id \
            -content_type "image"

        set tmp_filename "$::acs::rootdir/packages/acs-content-repository/tcl/test/test-image-1.jpg"
        set image_item_id_orig [db_nextval  "acs_object_id_seq"]
        set image_name [ns_mktemp "XXXXXX"]
        set image_item_id [image::new \
                               -item_id $image_item_id_orig \
                               -parent_id $first_folder_id \
                               -name $image_name \
                               -tmp_filename $tmp_filename]

        aa_true "Image Created" [expr {$image_item_id_orig eq $image_item_id}]
        aa_true "Image CR Item Exists" \
            [expr {$image_item_id eq [content::item::get_id \
                                          -item_path $image_name \
                                          -root_folder_id $first_folder_id]}]

    }
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
