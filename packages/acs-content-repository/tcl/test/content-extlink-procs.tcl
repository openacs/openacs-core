ad_library {

    Tests for extlinks

}

aa_register_case \
    -cats {api db} \
    -procs {
        content::extlink::new
        content::extlink::is_extlink
        content::extlink::edit
        content::extlink::delete
        content::extlink::copy
        content::extlink::name
        content::folder::register_content_type
    } \
    content_extlink {
        content extlink test
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {
            # Content repository should at least create 2 default folders
            # we can use for the test
            set parent_id [db_string get_parent {
                select min(object_id) from acs_objects
                where object_type = 'content_folder'
            }]
            set other_parent_id [db_string get_parent {
                select max(object_id) from acs_objects
                where object_type = 'content_folder'
            }]
            set user_id [db_string get_user {
                select min(user_id) from users
            }]

            # One must first register the content type on the folders
            foreach folder_id [list $parent_id $other_parent_id] {
                content::folder::register_content_type \
                    -folder_id $folder_id -content_type "content_extlink"
            }

            set url [ad_generate_random_string]
            set name [ad_generate_random_string]
            set label [ad_generate_random_string]
            set description [ad_generate_random_string]
            aa_log "Creating the link"
            set link_id [content::extlink::new \
                             -url $url \
                             -parent_id $parent_id \
                             -name $name \
                             -label $label \
                             -description $description]

            aa_true "New link is actually there" [content::extlink::is_extlink -item_id $link_id]

            aa_true "New link was saved with supplied info" [db_string check_info {
                select case when exists (select 1 from cr_extlinks e, cr_items i
                                         where extlink_id = :link_id
                                         and i.item_id = e.extlink_id
                                         and i.name = :name
                                         and url = :url
                                         and label = :label
                                         and description = :description) then 1 else 0 end
                from dual
            }]

            aa_log "Editing the link"
            set url [ad_generate_random_string]
            set label [ad_generate_random_string]
            set description [ad_generate_random_string]
            content::extlink::edit -extlink_id $link_id \
                -url $url \
                -label $label \
                -description $description

            aa_true "Link was edited with supplied info" [db_string check_info {
                select case when exists (select 1 from cr_extlinks where extlink_id = :link_id
                                         and url = :url
                                         and label = :label
                                         and description = :description) then 1 else 0 end
                from dual
            }]

            aa_equals "Link name is retrieved correctly" \
                $label [content::extlink::name -item_id $link_id]

            aa_log "Creating copy in the same folder $parent_id"
            aa_false "Copying in the same folder should just fail silently" [catch {
                content::extlink::copy -extlink_id $link_id \
                    -target_folder_id $parent_id \
                    -creation_user $user_id
            } errmsg]

            aa_log "Creating copy in different folder $other_parent_id"
            content::extlink::copy -extlink_id $link_id \
                -target_folder_id $other_parent_id \
                -creation_user $user_id
            set new_link_id [db_string get_new_link {
                select extlink_id from cr_extlinks e, cr_items i
                where i.item_id = e.extlink_id
                  and i.parent_id = :other_parent_id
                  and i.name = :name
            }]

            aa_true "Copy is retrieved correctly" [content::extlink::is_extlink -item_id $new_link_id]
            aa_equals "Copy has the same name" $label [content::extlink::name -item_id $new_link_id]

            aa_log "Deleting links"
            content::extlink::delete -extlink_id $link_id
            aa_false "Link $link_id is gone" [content::extlink::is_extlink -item_id $link_id]
            content::extlink::delete -extlink_id $new_link_id
            aa_false "Link $new_link_id is gone" [content::extlink::is_extlink -item_id $new_link_id]
        }
    }
