ad_library {
    Tests for application data links.
}

aa_register_case \
    -cats api \
    -procs {} \
    data_links_scan_links {
        Test scanning content for object URLs
} {
    # get a new object_id from the sequence, this object will not exist
    set nonexistent_object_id [db_nextval "acs_object_id_seq"]
    set text {Some random text <img src="/o/0"> <a href="/file/0"> <img src="/image/0"> <img src="/image/${nonexistent_object_id}/"> <img src="/image/0/thumbnail"> <img src="/image/0/info"> <a href="http://example.com/o/9">
              Some More Random Text <a href="/o/junk"> <a href="/file/junk"> <a href="/image/junk"> /o/10 /file/11 /image/12
        /o/[junk] /file/[junk] /image/[junk]
        /o/" /file/" /image/"
        /o/[ /file/[ /image/[

    } ;#"]
    append text "<a href=\"[ad_url]/o/0\"> "
    aa_log "ad_url = '[ad_url]'"
    set links [application_data_link::scan_for_links -text $text]
    set correct_links [list 0]
    aa_log "Links = '${links}'"
    aa_true "Number of links found is correct" {[llength $correct_links] eq [llength $links]}
}

aa_register_case \
    -cats api \
    -procs {
        application_data_link::scan_for_links
        application_data_link::update_links_from
        application_data_link::get_links_from
        content::item::new
    } \
    data_links_update_links {

        Test updating references, tests scan_for_links and delete_links in
        the process.

} {
    aa_run_with_teardown -rollback -test_code {
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
        set correct_links [lsort [application_data_link::scan_for_links \
                                      -text $text]]
        aa_true "Correct links is not empty" [llength $correct_links]
        foreach n [array names o] {
            set links [lsort [application_data_link::get_links_from \
                                  -object_id $o($n)]]
            aa_true "Object \#${n} references correct" \
                {$correct_links eq $links}
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
        set new_correct_links [lsort [application_data_link::scan_for_links \
                                          -text $new_text]]

        for {set i 0} {$i < 5} {incr i} {
            set links [lsort [application_data_link::get_links_from \
                                  -object_id $o($i)]]
            aa_true "Object \#${i} updated references correct" \
                {$new_correct_links eq $links}
        }
    }
}

aa_register_case \
    -cats api \
    -procs {
        application_data_link::scan_for_links
    } \
    data_links_scan_links_with_tag {

        Test scanning content for object URLs with relation tag.

} {
    # get a new object_id from the sequence, this object will not exist
    set nonexistent_object_id [db_nextval "acs_object_id_seq"]
    set text {Some random text <img src="/o/0"> <a href="/file/0"> <img src="/image/0"> <img src="/image/${nonexistent_object_id}/"> <img src="/image/0/thumbnail"> <img src="/image/0/info"> <a href="http://example.com/o/9">
              Some More Random Text <a href="/o/junk"> <a href="/file/junk"> <a href="/image/junk"> /o/10 /file/11 /image/12
    /o/[junk] /file/[junk] /image/[junk]
        /o/" /file/" /image/"
        /o/[ /file/[ /image/[

    } ;#"]
    append text "<a href=\"[ad_url]/o/0\"> "
    aa_log "ad_url = '[ad_url]'"
    set links [application_data_link::scan_for_links -text $text]
    set correct_links [list 0]
    aa_log "Links = '${links}'"
    aa_true "Number of links found is correct" \
        {[llength $correct_links] eq [llength $links]}

}

aa_register_case \
    -cats api \
    -procs {
        application_data_link::get_links_from
        application_data_link::scan_for_links
        application_data_link::update_links_from
        content::item::new
    } \
    data_links_update_links_with_tag {

        Test updating references, tests scan_for_links and
        delete_links in the process.  Uses relation tags.

} {
    aa_run_with_teardown -rollback -test_code {
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
            -text $text \
            -relation_tag tag
        }
        # scan for links and compare
        set correct_links [lsort \
                  [application_data_link::scan_for_links \
                       -text $text]]
        aa_true "Correct links is not empty" [llength $correct_links]
        foreach n [array names o] {
        set links [lsort \
                  [application_data_link::get_links_from \
                   -object_id $o($n) -relation_tag tag]]
        aa_true "Object \#${n} references correct" \
            {$correct_links eq $links}
        }
        # now change the text and update one of the objects
        for {set i 0} {$i < 5} {incr i} {
            append new_text "\nTest Content Link to $o($i) /o/$o($i) \n"
        }
        for {set i 0} {$i < 5} {incr i} {
        application_data_link::update_links_from \
            -object_id $o($i) \
            -text $new_text \
            -relation_tag tag
        }
        set new_correct_links [lsort \
                      [application_data_link::scan_for_links \
                       -text $new_text]]

        for {set i 0} {$i < 5} {incr i} {
        set links [lsort \
                  [application_data_link::get_links_from \
                   -object_id $o($i) \
                   -relation_tag tag]]
        aa_true "Object \#${i} updated references correct" \
            {$new_correct_links eq $links}
        }
    }
}


aa_register_case \
    -cats api \
    -procs {
        acs_object_type
        application_data_link::delete_links
        application_data_link::get
        application_data_link::get_linked
        application_data_link::get_linked_content
        application_data_link::link_exists
        application_data_link::new
        content::item::new
    } \
    data_links_with_tag {

        Test creating new link, exists test, get, get_linked and
        delete. Uses relation tags.

} {
    aa_run_with_teardown -rollback -test_code {
        # create some test objects
        set name [ns_mktemp "cr_item__XXXXXX"]

        for {set i 0} {$i<6} {incr i} {
        set o($i) [content::item::new \
                   -name ${name}_$i \
                   -title ${name}_$i]
        }

        aa_log "Creating link between objects"
        application_data_link::new -this_object_id $o(0) -target_object_id $o(1) -relation_tag tag

        aa_true "Verify objects are linked" \
            [application_data_link::link_exists \
                 -from_object_id $o(0) \
                 -to_object_id $o(1) \
                 -relation_tag tag]

        aa_log "Deleting links attached to first object"
        application_data_link::delete_links -object_id $o(0)

        aa_false "Verify objects are deleted" \
            [application_data_link::link_exists \
                 -from_object_id $o(0) \
                 -to_object_id $o(1) \
                 -relation_tag tag]

        aa_log "Creating many links between objects"
        application_data_link::new -this_object_id $o(0) -target_object_id $o(1) -relation_tag tag1
        application_data_link::new -this_object_id $o(0) -target_object_id $o(2) -relation_tag tag1
        application_data_link::new -this_object_id $o(0) -target_object_id $o(3) -relation_tag tag2
        application_data_link::new -this_object_id $o(3) -target_object_id $o(4) -relation_tag tag2
        application_data_link::new -this_object_id $o(3) -target_object_id $o(5) -relation_tag tag2

        aa_true "Verify link for tag1" \
            {[llength [application_data_link::get_linked -from_object_id $o(0) \
                           -to_object_type [acs_object_type $o(0)] -relation_tag tag1]] == 2}

        aa_true "Verify link for tag2" \
            {[llength [application_data_link::get_linked -from_object_id $o(3) \
                           -to_object_type [acs_object_type $o(3)] -relation_tag tag2]] == 3}

        aa_true "Verify content link" \
            {[llength [application_data_link::get_linked_content -from_object_id $o(0) \
                           -to_content_type content_revision -relation_tag tag1]] == 2}

        aa_true "Verify links to one object with multiple link tags" \
            {[llength [application_data_link::get -object_id $o(0) -relation_tag tag1]] == 2}

        aa_true "Verify links to one object with multiple link tags" \
            {[llength [application_data_link::get -object_id $o(0) -relation_tag tag2]] == 1}

    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
