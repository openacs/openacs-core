ad_library {
    Test cases for my first package.
}

aa_register_case mfp_basic_test {
    Test One
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

