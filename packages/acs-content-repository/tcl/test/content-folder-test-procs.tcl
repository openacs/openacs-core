# 

ad_library {
    
    Tests for content folders
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-01-13
    @arch-tag: ce944027-3808-4e8d-9327-5d1377074643
    @cvs-id $Id$
}

aa_register_case content_folder {
    content folder test
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
            # allow subfolders inside our parent test folder
            content::folder::register_content_type \
                -folder_id $first_folder_id \
                -content_type content_folder
            

            #########################################################
            # Update the folder
            #########################################################
            content::folder::update \
                -folder_id $first_folder_id \
                -attributes {{label new_label} {description new_description}}
            content::item::get \
                -item_id $first_folder_id \
                -array_name first_folder
            aa_true "Folder updated" [expr {($first_folder(label) eq "new_label") && ($first_folder(description) eq "new_description")}]
                                          
            #########################################################
            # create a child folder
            #########################################################
            set child_folder_id [db_nextval "acs_object_id_seq"]
            set returned_child_folder_id [content::folder::new \
                                              -folder_id $child_folder_id \
                                              -parent_id $first_folder_id \
                                              -name "test_folder_${first_folder_id}"]
            #########################################################
            # check if child is a subfolder of parent
            #########################################################
            set is_subfolder [content::folder::is_sub_folder \
                                  -folder_id $first_folder_id \
                                  -target_folder_id $child_folder_id]
            aa_true "Child is subfolder" [string equal "t" $is_subfolder]
            
            #########################################################
            # make sure parent is not a subfolder of child
            #########################################################
            set is_subfolder [content::folder::is_sub_folder \
                                  -folder_id $child_folder_id \
                                  -target_folder_id $first_folder_id]
            aa_true "Parent is not subfolder of child" [string equal "f" $is_subfolder]            
            
        }
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
