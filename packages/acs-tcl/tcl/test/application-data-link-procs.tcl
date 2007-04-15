ad_library {
    Tests for applicaiton data links
}

aa_register_case -cats api data_links_scan_links {
    Test scanning content for object URLs
} {
    set text {Some random text <img src="/o/0"> <a href="/file/0"> <img src="/image/0"> <img src="/image/4/"> <img src="/image/0/thumbnail"> <img src="/image/0/info"> <a href="http://example.com/o/9">
              Some More Random Text <a href="/o/junk"> <a href="/file/junk"> <a href="/image/junk"> /o/10 /file/11 /image/12
	/o/[junk] /file/[junk] /image/[junk]
        /o/" /file/" /image/"
        /o/[ /file/[ /image/[
       
    }
    append text "<a href=\"[ad_url]/o/0\"> "
    aa_log "ad_url = '[ad_url]'"
    set links [application_data_link::scan_for_links -text $text]
    set correct_links [list 0]
    aa_log "Links = '${links}'"
    aa_true "Number of links found is correct" \
        [expr {[llength $correct_links] eq [llength $links]}]

}

aa_register_case -cats api data_links_update_links {
    Test updating references,
    tests scan_for_links
    and delete_links in the process
} {
    aa_run_with_teardown \
	-rollback \
	-test_code \
	{
	    # create some test objects
	    set name [ns_mktemp "cr_item__XXXXXX"]
	    
	    for {set i 0} {$i<10} {incr i} {
		set o($i) [content::item::new \
			       -name ${name}_$i \
			       -title ${name}_$i]
	    }
	    
	    # generate some text with links between the objects
	    foreach n [array names o] {
		append text "\nTest Content Link to $o($n) <a href=\"/o/$o($n)\">Link</a> \n"
	    }
	    # update the links
	    foreach n [array names o] {
		application_data_link::update_links_from \
		    -object_id $o($n) \
		    -text $text
	    }
	    # scan for links and compare
	    set correct_links [lsort \
				  [application_data_link::scan_for_links \
				       -text $text]]
	    aa_true "Correct links is not empty" [llength $correct_links]
	    foreach n [array names o] {
		set links [lsort \
			      [application_data_link::get_links_from \
				   -object_id $o($n)]]
		aa_true "Object \#${n} references correct" \
		    [expr {$correct_links eq $links}]
	    }
	    # now change the text and update one of the objects
	    for {set i 0} {$i < 5} {incr i} {
		    append new_text "\nTest Content Link to $o($i) /o/$o($i) \n"
	    }
	    for {set i 0} {$i < 5} {incr i} {
		application_data_link::update_links_from \
		    -object_id $o($i) \
		    -text $new_text
	    }
	    set new_correct_links [lsort \
				      [application_data_link::scan_for_links \
					   -text $new_text]]

	    for {set i 0} {$i < 5} {incr i} {
		set links [lsort \
			      [application_data_link::get_links_from \
				   -object_id $o($i)]]
		aa_true "Object \#${i} updated references correct" \
		    [expr {$new_correct_links eq $links}]
	    }
	}
}