ad_library {
    Procedures to test content::revision tcl API

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    @arch-tag: e8817de4-54e8-48f6-99bc-49c0a8d94691
    @cvs-id $Id$
}


aa_register_case content_revision {
    content revision test
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # create a cr_folder
            set first_folder_id [db_nextval "acs_object_id_seq"]
            set returned_first_folder_id [content::folder::new \
                                              -folder_id $first_folder_id \
                                              -name "test_folder_${first_folder_id}"]
            aa_true "Folder created" [expr {$first_folder_id == $returned_first_folder_id}]

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

            aa_true "First item created $first_item_id" [expr {$first_item_id == $returned_first_item_id}]

            # create a revision
            set revision_id [db_nextval "acs_object_id_seq"]

            set returned_revision_id [content::revision::new \
                                          -revision_id $revision_id \
                                          -item_id $first_item_id \
                                          -title "Test Title" \
                                          -description "Test Description" \
                                          -content "Test Content"]
            aa_true "Basic Revision created revision_id $revision_id returned_revision_id $returned_revision_id " [expr {$revision_id == $returned_revision_id}]

	::item::get_content -revision_id $returned_revision_id -array revision_content
	set revision_content(content) [cr_write_content -revision_id $returned_revision_id -string]
        aa_true "Revision contains correct content" [expr {
 	    $revision_content(title) eq "Test Title"
	    && $revision_content(content) eq "Test Content" 
	    && $revision_id == $revision_content(revision_id)}]
	    
            content::item::delete -item_id $first_item_id

            content::folder::unregister_content_type \
                -folder_id $first_folder_id \
                -content_type "content_revision" \

            content::folder::delete -folder_id $first_folder_id
        }
}
