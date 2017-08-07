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
                aa_true "Note add succeeded" ([info exists new_id] && $new_id ne "")
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr {$get_again == 0}]
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
                aa_true "Note add succeeded" ([info exists new_id] && $new_id ne "")
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                aa_log "Title is $name"
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr {$get_again == 0}]
            }
    }


aa_register_case \
    -cats {web smoke} \
    -libraries tclwebtest \
    mfp_web_basic_test \
    {
        A simple tclwebtest test case for the tutorial demo package.
        
        @author Peter Marklund
    } {
        # we need to get a user_id here so that it's available throughout
        # this proc
        set user_id [db_nextval acs_object_id_seq]

        set note_title [ad_generate_random_string]

        # NOTE: Never use the aa_run_with_teardown with the rollback switch
        # when running Tclwebtest tests since this will put the test code in
        # a transaction and changes won't be visible across HTTP requests.
        
        aa_run_with_teardown -test_code {
            
            #-------------------------------------------------------------
            # Login
            #-------------------------------------------------------------
            
            # Make a site-wide admin user for this test
            # We use an admin to avoid permission issues
            array set user_info [twt::user::create -admin -user_id $user_id]
            
            # Login the user
            twt::user::login $user_info(email) $user_info(password)
            
            #-------------------------------------------------------------
            # New Note
            #-------------------------------------------------------------
            
            # Request note-edit page
            set package_uri [apm_package_url_from_key myfirstpackage]
            set edit_uri "${package_uri}note-edit"
            aa_log "[twt::server_url]$edit_uri"
            twt::do_request "[twt::server_url]$edit_uri"
            
            # Submit a new note

            tclwebtest::form find ~n note
            tclwebtest::field find ~n title
            tclwebtest::field fill $note_title
            tclwebtest::form submit
            
            #-------------------------------------------------------------
            # Retrieve note
            #-------------------------------------------------------------
            
            # Request index page and verify that note is in listing
            tclwebtest::do_request $package_uri                 
            aa_true "New note with title \"$note_title\" is found in index page" \
                [string match "*${note_title}*" [tclwebtest::response body]]
            
            #-------------------------------------------------------------
            # Delete Note
            #-------------------------------------------------------------
            # Delete all notes

            # Three options to delete the note
            # 1) go directly to the database to get the id
            # 2) require an API function that takes name and returns ID
            # 3) screen-scrape for the ID
            # all options are problematic.  We'll do #1 in this example:

            set note_id [db_string get_note_id_from_name " 
                select item_id 
                  from cr_items 
                 where name = :note_title  
                   and content_type = 'mfp_note'
            " -default 0]

            aa_log "Deleting note with id $note_id"

            set delete_uri "${package_uri}note-delete?item_id=${note_id}"
            twt::do_request $delete_uri
            
            # Request index page and verify that note is in listing
            tclwebtest::do_request $package_uri                 
            aa_true "Note with title \"$note_title\" is not found in index page after deletion." \
                ![string match "*${note_title}*" [tclwebtest::response body]]
            
        } -teardown_code {
            
            twt::user::delete -user_id $user_id
        }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
