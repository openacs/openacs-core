ad_library {
    Test cases for my first package.
}

aa_register_case \
    -cats {smoke api} \
    -procs {mfp::note::add mfp::note::get mfp::note::delete} \
    mfp_basic_test \
    {
        A simple test that adds, retrieves, and deletes a record.
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code  {
                set name [ad_generate_random_string]
                set new_id [mfp::note::add -title $name]
                aa_true "Note add succeeded" [exists_and_not_null new_id]
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr $get_again == 0]
            }
    }

aa_register_case \
    -cats {api} \
    -procs {mfp::note::add mfp::note::get mfp::note::delete} \
    mfp_bad_data_test \
    {
        A simple test that adds, retrieves, and deletes a record, using some tricky data.
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code  {
                set name {-Bad [BAD] \077 { $Bad}} 
                append name [ad_generate_random_string]
                set new_id [mfp::note::add -title $name]
                aa_true "Note add succeeded" [exists_and_not_null new_id]
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                aa_log "Title is $name"
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr $get_again == 0]
            }
    }

aa_register_case \
    -libraries tclwebtest \
    -cats {web} \
    mfp_basic_web_test \
    {
        A simple test that adds, retrieves, and deletes a record through the web interface.  INCOMPLETE.
     } {
        aa_run_with_teardown \
            -rollback \
            -test_code  {
                ############################################
                # Prepare
                ############################################

                set name [ad_generate_random_string]

                tclwebtest::do_request 


                set new_id [mfp::note::add -title $name]
                aa_true "Note add succeeded" [exists_and_not_null new_id]
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                aa_log "Title is $name"
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr $get_again == 0]
            }
    }