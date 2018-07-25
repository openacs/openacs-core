ad_library {
    Tests for additional utilities.
    @creation-date 03 August 2006
}

aa_register_case \
    -cats {api smoke} \
    -procs {oacs_util::csv_foreach} \
    csv_foreach {
    Test block execution for rows in a csv file.
} {
    aa_run_with_teardown -test_code {
	
	# Create cvs file
	set file_loc "/tmp/test.csv"
	set file_id [open $file_loc w]
	puts $file_id "first_name,last_name,instrument"
	puts $file_id "Charles,Mingus,Bass"
	puts $file_id "Miles,Davis,Trumpet"
	puts $file_id "Jhon,Coltrane,Saxo"
	puts $file_id "Charlie,Parker,Saxo"
	puts $file_id "Thelonius,Monk,Piano"
	close $file_id
	
	set csv_data "\nfirst_name,last_name,instrument\nCharles,Mingus,Bass\nMiles,Davis,Trumpet\nJhon,Coltrane,Saxo\nCharlie,Parker,Saxo\nThelonius,Monk,Piano"

	aa_log "CSV file created with artists data:\n $csv_data"

	set artist_list {}
	oacs_util::csv_foreach -file $file_loc -array_name row {
            lappend artist_list "$row(first_name) $row(last_name) - $row(instrument)"
        }
	aa_equals "Getting artists from csv file" $artist_list {{Charles Mingus - Bass}\
                                                                    {Miles Davis - Trumpet}\
                                                                    {Jhon Coltrane - Saxo}\
                                                                    {Charlie Parker - Saxo}\
                                                                    {Thelonius Monk - Piano}}
    } -teardown_code { 
	file delete -force -- $file_loc
    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        oacs_util::process_objects_csv
        person::get
    } \
    process_objects_csv {
    Test object creation for every row in a csv file.
} {
    aa_run_with_teardown -rollback -test_code {

        # Create cvs file of persons
        set file_loc "/tmp/test.csv"
        set file_id [open $file_loc w]
        puts $file_id "email,first_names,last_name"
        puts $file_id "cmingus@foo.bar,Charles,Mingus"
        puts $file_id "mdavis@foo.bar,Miles,Davis"
        puts $file_id "cparker@foo.bar,Charlie,Parker"
        close $file_id

	set csv_data "\nemail,first_names,last_name\ncmingus@foo.bar,Charles,Mingus\nmdavis@foo.bar,Miles,Davis\ncparker@foo.bar,Charlie,Parker"
        aa_log "CSV file for \"person\" objects creation with data:\n $csv_data"

	set person_ids [oacs_util::process_objects_csv -object_type "person" -file $file_loc]

	aa_log "Persons id's created: $person_ids"

	set person_list {}

	foreach person_id $person_ids {
	    array set person_array [person::get -person_id $person_id]
	    lappend person_list "$person_array(first_names) $person_array(last_name)"
	}
	aa_equals "Getting persons from database table \"persons\"" $person_list {{Charles Mingus}\
                                                                                      {Miles Davis}\
                                                                                      {Charlie Parker}}
    } -teardown_code {
        file delete -force -- $file_loc
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
