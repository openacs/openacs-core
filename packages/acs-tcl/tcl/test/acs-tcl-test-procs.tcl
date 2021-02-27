ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the acs-tcl package.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 22 January 2003
}

ad_proc -private apm_test_callback_file_path {} {
    The path of the test file used to check that the callback proc executed ok.
} {
    return "[acs_package_root_dir acs-tcl]/tcl/test/callback_proc_test_file"
}

ad_proc -private apm_test_callback_proc {
    {-arg1:required}
    {-arg2:required}
} {
    Writes the arbitrary values of arg1 and arg2 to a file so that we can
    check that the proc was executed.

    @param arg1 Arbitrary value.
    @param arg2 Arbitrary value.
} {
    # Write something to a file so that can check that the proc executed
    set file_path [apm_test_callback_file_path]
    set file_id [open $file_path w]
    puts $file_id "$arg1 $arg2"
    close $file_id
}


aa_register_case \
    -cats {api smoke} \
    -procs util_sets_equal_p \
    util__sets_equal_p {
        Test the util_sets_equal_p proc.

        @author Peter Marklund
} {
    aa_true "lists are identical sets" [util_sets_equal_p [list a a a b b c] [list c a a b b a]]
    aa_true "lists are identical sets 2" [util_sets_equal_p [list a b c] [list a b c]]
    aa_false "lists are not identical sets" [util_sets_equal_p [list a a a b b c] [list c c a b b a]]
    aa_false "lists are not identical sets 2" [util_sets_equal_p [list a b c] [list a b c d]]
}

# By stubbing this proc we can define callbacks valid only during testing
# that are guaranteed not to interfere with any real callbacks in the system
aa_stub apm_supported_callback_types {
    return [list __test-callback-type]
}

aa_stub apm_arg_names_for_callback_type {
    return [list arg1 arg2]
}

aa_register_case \
    -cats {api db smoke} \
    -procs {
        acs_package_root_dir
        apm_generate_package_spec
        apm_read_package_info_file
        apm_supported_callback_types
        db_dml

        apm_attribute_value
        db_1row
    } \
    apm__test_info_file {
        Test that the procs for interfacing with package info files -
        apm_generate_package_spec and
        apm_read_package_info_file - handle the newly added
        callback and auto-mount tags properly.

        @creation-date 22 January 2003
        @author Peter Marklund
} {
    set test_dir "[acs_package_root_dir acs-tcl]/tcl/test"
    set spec_path "${test_dir}/tmp-test-info-file.xml"
    set allowed_type [lindex [apm_supported_callback_types] 0]
    array set callback_array [list unknown-type proc_name1 $allowed_type proc_name2]
    set version_id [db_string aa_version_id {select version_id
                                            from apm_enabled_package_versions
                                            where package_key = 'acs-automated-testing'}]
    set auto_mount_orig [db_string aa_auto_mount {select auto_mount
                                             from apm_package_versions
                                             where version_id = :version_id}]
    set auto_mount $auto_mount_orig
    if { $auto_mount eq "" } {
        set auto_mount "test_auto_mount_dir"
        db_dml set_test_mount {update apm_package_versions
                               set auto_mount = :auto_mount
                               where version_id = :version_id}
        }

    set error_p [catch {
        # Add a few test callbacks
        foreach {type proc} [array get callback_array] {
          db_dml insert_callback {insert into apm_package_callbacks
                                       (version_id, type, proc)
                                values (:version_id, :type, :proc)}
        }

        # Get the xml string
        set spec [apm_generate_package_spec $version_id]

        # Write xml to file
        set spec_file_id [open $spec_path w]
        puts $spec_file_id $spec
        close $spec_file_id

        # Read the XML file
        array set spec_array [apm_read_package_info_file $spec_path]

        # Assert that info parsed from XML file is correct
        array set parsed_callback_array $spec_array(callbacks)

        aa_true "Only one permissible callback should be returned, got array [array get parsed_callback_array]" \
            {[array size parsed_callback_array] == 1}

        aa_equals "Checking name of callback of allowed type $allowed_type" \
                $parsed_callback_array($allowed_type) $callback_array($allowed_type)

        aa_equals "Checking that auto-callback is correct" $spec_array(auto-mount) $auto_mount

    } error]

    # Teardown
    file delete -- $spec_path
    foreach {type proc} [array get callback_array] {
      db_dml remove_callback {delete from apm_package_callbacks
                              where version_id = :version_id
                              and type = :type }
    }
    db_dml reset_auto_mount {update apm_package_versions
                             set auto_mount = :auto_mount_orig
                             where version_id = :version_id}


    if { $error_p } {
        error "$error - $::errorInfo"
    }
}

aa_register_case \
    -cats {api db smoke} \
    -procs {
        apm_get_callback_proc
        apm_set_callback_proc
        apm_package_install_callbacks
        apm_remove_callback_proc
        apm_post_instantiation_tcl_proc_from_key
        apm_supported_callback_types
        apm_version_id_from_package_key
    } \
    apm__test_callback_get_set {
        Test the procs apm_get_callback_proc,
                       apm_set_callback_proc,
                       apm_package_install_callbacks
                       apm_remove_callback_proc,
                       apm_post_instantiation_tcl_proc_from_key.

        @author Peter Marklund
} {
    # The proc should not accept an invalid callback type
    set invalid_type "not-allowed-type"
    set error_p [catch {apm_get_callback_proc -type $invalid_type -package_key acs-kernel} error]
    aa_true "invalid types should result in error, got error: $error" $error_p

    # Try setting a package callback proc
    set callback_type [lindex [apm_supported_callback_types] 0]
    set proc_name "test_proc"
    set package_key "acs-automated-testing"
    set version_id [apm_version_id_from_package_key $package_key]

    set error_p [catch {
        apm_package_install_callbacks [list $callback_type $proc_name] $version_id

        # Retrieve the callback proc
        set retrieved_proc_name \
                [apm_get_callback_proc -package_key $package_key \
                                       -type $callback_type]
        aa_equals "apm_get_callback_proc retrieve callback proc" \
                  $retrieved_proc_name $proc_name
    } error]

    # Teardown
    apm_remove_callback_proc -package_key $package_key -type $callback_type

    if { $error_p } {
        error "$error - $::errorInfo"
    }
}

aa_register_case \
    -cats {db api smoke} \
    -procs {
        apm_invoke_callback_proc
        apm_remove_callback_proc
        apm_set_callback_proc
        apm_supported_callback_types
        apm_test_callback_file_path
        apm_version_id_from_package_key

        apm_callback_format_args
        apm_test_callback_proc
    } apm__test_callback_invoke {
        Test the proc apm_invoke_callback_proc

        @author Peter Marklund
} {
    set package_key acs-automated-testing
    set version_id [apm_version_id_from_package_key $package_key]
    set type [lindex [apm_supported_callback_types] 0]
    set file_path [apm_test_callback_file_path]

    set error_p [catch {

        # Set the callback to be to our little test proc
        apm_set_callback_proc -version_id $version_id -type $type "apm_test_callback_proc"

        apm_invoke_callback_proc -version_id $version_id -arg_list [list arg1 value1 arg2 value2] -type $type

        set file_id [open $file_path r]
        set file_contents [read $file_id]
        aa_equals "The callback proc should have been executed and written argument values to file" \
                [string trim $file_contents] "value1 value2"
        close $file_id

        # Provide invalid argument list and the invoke proc should bomb
        # TODO...
    } error]

    # Teardown
    file delete -- $file_path
    apm_remove_callback_proc -package_key $package_key -type $type

    if { $error_p } {
        error "$error - $::errorInfo"
    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        xml_doc_get_first_node
        xml_get_child_node_content_by_path
        xml_parse
    } \
    xml_get_child_node_content_by_path {
        Test xml_get_child_node_content_by_path
} {
    set tree [xml_parse -persist {
<enterprise>
  <properties>
    <datasource>Dunelm Services Limited</datasource>
    <target>Telecommunications LMS</target>
    <type>DATABASE UPDATE</type>
    <datetime>2001-08-08</datetime>
  </properties>
  <person recstatus = "1">
    <comments>Add a new Person record.</comments>
    <sourcedid>
      <source>Dunelm Services Limited</source>
      <id>CK1</id>
    </sourcedid>
    <name>
      <fn>Clark Kent</fn>
      <sort>Kent, C</sort>
      <nickname>Superman</nickname>
    </name>
    <demographics>
      <gender>2</gender>
    </demographics>
    <adr>
      <extadd>The Daily Planet</extadd>
      <locality>Metropolis</locality>
      <country>USA</country>
    </adr>
  </person>
</enterprise>
    }]

    set root_node [xml_doc_get_first_node $tree]

    aa_equals "person -> name -> nickname is Superman" \
        [xml_get_child_node_content_by_path $root_node { { person name nickname } }] "Superman"

    aa_equals "Same, but after trying a couple of non-existent paths or empty notes" \
        [xml_get_child_node_content_by_path $root_node { { does not exist } { properties } { person name nickname } { person sourcedid id } }] "Superman"
    aa_equals "properties -> datetime" \
        [xml_get_child_node_content_by_path $root_node { { person comments foo } { person name first_names } { properties datetime } }] "2001-08-08"


}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        site_node::get_children
        site_node::get_node_id

        db_1row
    } -on_error {
        site_node::get_children returns root node!
    } site_node_get_children {
    Test site_node::get_children
} {
    #
    # Check if the number of nodes in the system is large, and avoid testing
    # on all children if that is the case, as it can take too long
    #
    set max_nodes 1000
    set current_nodes [db_string nodes_number {select count(1) from site_nodes}]
    if {$current_nodes > $max_nodes} {
        set all_switch {}
        aa_log "Large number of nodes ($current_nodes > $max_nodes), testing only the root node and its direct children"
    } else {
        set all_switch {-all}
    }
    #
    # Start with a known site-map entry
    #
    set node_id         [site_node::get_node_id -url "/"]
    set child_node_ids  [site_node::get_children \
                            -element node_id \
                            {*}$all_switch \
                            -node_id $node_id]
    #
    # Check that site_node::get_children does not return the root node
    # (lsearch returns '-1' if not found)
    #
    aa_equals "site_node::get_children does not return root node" [lsearch -exact $child_node_ids $node_id] -1
    #
    # Filter by package_key should be equivalent to using -package_key
    #
    set nodes [site_node::get_children -element node_id {*}$all_switch -node_id $node_id -filters { package_key "acs-admin" }]
    aa_equals "package_key arg. identical to -filters" \
        [site_node::get_children -element node_id {*}$all_switch -node_id $node_id -package_key "acs-admin"] \
        $nodes
    aa_equals "Found exactly one acs-admin node" [llength $nodes] 1
    #
    # Filtering by package_type should be equivalent to using -package_type
    #
    set nodes [site_node::get_children -element node_id {*}$all_switch -node_id $node_id -filters { package_type "apm_service" }]
    aa_equals "package_type arg. identical to filter_element package_type" \
        [site_node::get_children -element node_id {*}$all_switch -node_id $node_id -package_type "apm_service"] \
        $nodes

    aa_true "Found at least one apm_service node" {[llength $nodes] > 0}
    #
    # Check for nonexistent package_type
    #
    aa_true "No nodes with package type 'foo'" \
        {[llength [site_node::get_children -element node_id {*}$all_switch -node_id $node_id -package_type "foo"]] == 0}
}

aa_register_case \
    -cats {api smoke} \
    -procs ad_html_to_text \
    html_to_text {
        Test code the supposedly causes ad_html_to_text to break
} {

    # Test bad <<<'s

    set offending_post {><<<}
    set errno [catch { set text_version [ad_html_to_text -- $offending_post] } errmsg]

    if { ![aa_equals "Does not bomb" $errno 0] } {
                aa_log "errmsg: $errmsg"
        aa_log "errorInfo: $::errorInfo"
    } else {
        aa_equals "Expected identical result" $text_version $offending_post
    }

    # Test offending post sent by Dave Bauer

    set offending_post {
I have a dynamically assigned IP address, so I use dyndns.org to
change
addresses for my acs server.
Mail is sent to any yahoo address fine. Mail sent to aol fails. I am
not running a dns server on my acs box. What do I need to do to
correct this problem?<br>
Here's my error message:<blockquote>
            Mail Delivery Subsystem<br>
<MAILER-DAEMON@testdsl.homeip.net>  | Block
            Address | Add to Address Book<br>
       To:
            gmt3rd@yahoo.com<br>
 Subject:
            Returned mail: Service unavailable
<p>


The original message was received at Sat, 17 Mar 2001 11:48:57 -0500
from IDENT:nsadmin@localhost [127.0.0.1]
<br>
   ----- The following addresses had permanent fatal errors -----
gmt3rd@aol.com
<br>
   ----- Transcript of session follows -----<p>
... while talking to mailin-04.mx.aol.com.:
<<< 550-AOL no longer accepts connections from dynamically assigned
<<< 550-IP addresses to our relay servers.  Please contact your ISP
<<< 550 to have your mail redirected through your ISP's SMTP servers.
... while talking to mailin-02.mx.aol.com.:
>>> QUIT
<p>

                              Attachment: Message/delivery-status

Reporting-MTA: dns; testdsl.homeip.net
Received-From-MTA: DNS; localhost
Arrival-Date: Sat, 17 Mar 2001 11:48:57 -0500

Final-Recipient: RFC822; gmt3rd@aol.com
Action: failed
Status: 5.5.0
Remote-MTA: DNS; mailin-01.mx.aol.com
Diagnostic-Code: SMTP; 550-AOL no longer accepts connections from
dynamically assigned
Last-Attempt-Date: Sat, 17 Mar 2001 11:48:57 -0500

</blockquote>
<p>
anybody have any ideas?
    }

    set errno [catch { set text_version [ad_html_to_text -- $offending_post] } errmsg]

    if { ![aa_equals "Does not bomb" $errno 0] } {
        aa_log "errmsg: $errmsg"
        aa_log "errorInfo: $::errorInfo"
    } else {
        aa_log "Text version: $text_version"
    }

    # Test placement of [1] reference
    set html {Here is <a href="http://openacs.org">http://openacs.org</a> my friend}

    set text_version [ad_html_to_text -- $html]

    aa_log "Text version: $text_version"
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_page_contract_filter_invoke

        ad_complain
    } ad_page_contract_filters {
        Test ad_page_contract_filters
} {
    set filter integer
    foreach { value result } { "1" 1 "a" 0 "1.2" 0 "'" 0 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }

    set filter naturalnum
    foreach { value result } { "1" 1 "-1" 0 "a" 0 "1.2" 0 "'" 0 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }

    set filter html
    foreach { value result } { "'" 1 "<p>" 1 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }

    set filter nohtml
    foreach { value result } { "a" 1 "<p>" 0 } {
        if { $result } {
            aa_true "$value is $filter" [ad_page_contract_filter_invoke $filter dummy value]
        } else {
            aa_false "$value is NOT $filter" [ad_page_contract_filter_invoke $filter dummy value]
        }
    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        export_vars
        ad_urlencode_url
    } \
     export_vars {
        Testing export_vars
} {
    set foo 1
    set bar {}

    aa_equals "{ foo bar }" \
        [export_vars { foo bar }] \
        "foo=1&bar="

    aa_equals "-no_empty { foo bar }" \
        [export_vars -no_empty { foo bar }] \
        "foo=1"

    aa_equals "-no_empty { foo bar { baz greble } }" \
        [export_vars -no_empty { foo bar { baz greble } }] \
        "foo=1&baz=greble"

    aa_equals "-no_empty -override { { bar \"\" } } { foo bar }" \
        [export_vars -no_empty -override { { bar "" } } { foo bar }] \
        "foo=1&bar=" \

    aa_equals "-no_empty -override { { baz greble } } { foo bar }" \
        [export_vars -no_empty -override { baz } { foo bar }] \
        "foo=1"

    aa_equals "-no_empty { foo { bar \"\" } }" \
        [export_vars -no_empty { foo { bar "" } }] \
        "foo=1&bar="

    aa_equals "base ending with '?', with vars" \
        [export_vars -base "dummy?" { foo { bar "" } }] \
        "dummy?foo=1&bar="

    aa_equals "base ending with '?', no vars" \
        [export_vars -base "dummy?"] \
        "dummy"

    aa_equals "base containing more than two slashes " \
        [export_vars -base "http://dummywebsite.com/one/two" {{foo a} {bar b}}] \
        "http://dummywebsite.com/one/two?foo=a&bar=b"

    # Test base with query vars
    set var1 a
    set var2 {}
    set base [export_vars -base test-page { foo bar }]
    set export_no_base [export_vars {var1 var2}]
    aa_equals "base with query vars" \
        [export_vars -base $base {var1 var2}] \
        "$base&$export_no_base"

    # Test base without query vars
    set base test-page
    aa_equals "base without query vars" \
        [export_vars -base $base {var1 var2}] \
        "$base?$export_no_base"

    # Test just ad_urlencode_url (used by export_vars)
    set url http://example.com/example
    aa_equals "complex URL" \
        [ad_urlencode_url $url] \
        $url

    set url http://example.com/foo=1/bar
    aa_equals "complex URL with char which has to be escaped" \
        [ad_urlencode_url $url] \
        http://example.com/foo%3d1/bar

    # Test just ad_urlencode_url: location without trailing slash
    set url http://example.com
    aa_equals "URL with trailing slash" \
        [ad_urlencode_url $url] \
        $url/

    # Test just ad_urlencode_url: location with trailing slash
    set url http://example.com/
    aa_equals "URL without trailing slash" \
        [ad_urlencode_url $url] \
        $url

    set url http://dummywebsite.com/one/two
    aa_equals "base with path containing more than 1 slash" \
        [ad_urlencode_url $url] \
        $url

    # Test full qualified base without query vars
    set base http://example.com/example
    aa_equals "base without query vars" \
        [export_vars -base $base] \
        $base

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        site_node::exists_p
        site_node::get_children
        site_node::get_element
        site_node::get_node_id
        site_node::verify_folder_name
    } \
    site_node_verify_folder_name {
    Testing site_node::verify_folder_name
} {
    set main_site_node_id [site_node::get_node_id -url /]

    # Try a few folder names which we know exist
    aa_equals "Folder name 'user' is not allowed" \
        [site_node::verify_folder_name -parent_node_id $main_site_node_id -folder "user"] ""
    aa_equals "Folder name 'pvt' is not allowed" \
        [site_node::verify_folder_name -parent_node_id $main_site_node_id -folder "pvt"] ""

    # Try one we believe will be allowed
    set folder [ad_generate_random_string]
    aa_equals "Folder name '$folder' is allowed" \
        [site_node::verify_folder_name -parent_node_id $main_site_node_id -folder $folder] $folder

    # Try the code that generates a folder name
    # (We only want to try this if there doesn't happen to be a site-node named user-2)
    if { ![site_node::exists_p -url "/register-2"] } {
        aa_equals "Instance name 'Register'" \
            [site_node::verify_folder_name -parent_node_id $main_site_node_id -instance_name "register"] "register-2"
    }

    set first_child_node_id [lindex [site_node::get_children -node_id $main_site_node_id -element node_id] 0]
    set first_child_name [site_node::get_element -node_id $first_child_node_id -element name]

    aa_equals "Renaming folder '$first_child_name' ok" \
            [site_node::verify_folder_name \
                 -parent_node_id $main_site_node_id \
                 -folder $first_child_name \
                 -current_node_id $first_child_node_id] $first_child_name

    aa_false "Creating new folder named '$first_child_name' not ok" \
        [string equal [site_node::verify_folder_name \
                           -parent_node_id $main_site_node_id \
                           -folder $first_child_name] $first_child_name]

}




aa_register_case \
    -cats {api smoke production_safe} \
    -procs util_subset_p \
    util_subset_p {
        Test the util_subset_p proc.

        @author Peter Marklund
} {
    aa_true "List is a subset" [util_subset_p [list c b] [list c a a b b a]]
    aa_true "List is a subset" [util_subset_p [list a b c] [list c a b]]
    aa_false "List is not a subset" [util_subset_p [list a a a b b c] [list c c a b b a]]
    aa_false "List is not a subset" [util_subset_p [list a b c d] [list a b c]]
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util_get_subset_missing \
    util_get_subset_missing {
        Test the util_get_subset_missing proc.
} {

    aa_equals "List A {a b d d e f g} contains elements that are not in list B {a b c e g} (duplicates being ignored)" [util_get_subset_missing [list a b d d e f g] [list a b c e g]] [list d f]
    aa_equals "List A {a a a b b c} contains no elements that are not in list B {c c a b b e d a e} (duplicates being ignored) " [util_get_subset_missing [list a a a b b c] [list c c a b b e d a e]] [list]

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        util::randomize_list
        util::random_range
    } \
    util__randomize_list {
        Test util::randomize_list
} {
    aa_equals "Empty list" [util::randomize_list {}] {}

    aa_equals "One-element list" [util::randomize_list {a}] {a}

    aa_true "Two-element list" [util_sets_equal_p [list a b] [util::randomize_list [list a b]]]

    set org_list [list a b c d e f g h i j]
    set randomized_list [util::randomize_list $org_list]
    aa_true "Ten-element list: $randomized_list" [util_sets_equal_p $org_list $randomized_list]

    set len [util::random_range 200]
    set org_list [list]
    for { set i 0 } { $i < $len } { incr i } {
        lappend org_list [ad_generate_random_string]
    }
    set randomized_list [util::randomize_list $org_list]
    aa_true "Long random list" [util_sets_equal_p $org_list $randomized_list]
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util::trim_leading_zeros \
    util__trim_leading_zeros {

        Test util::trim_leading_zeros

        @creation-date 2018-09-17
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    aa_equals "Empty value" [util::trim_leading_zeros {}] {}
    aa_equals "Real value (0.31)" [util::trim_leading_zeros 0.31] {.31}
    aa_equals "Real value with multiple leading zeros (000.31)" [util::trim_leading_zeros 0000.31] {.31}
    aa_equals "Real value already trimmed (.31)" [util::trim_leading_zeros .31] {.31}
    aa_equals "Natural value (031)" [util::trim_leading_zeros 031] {31}
    aa_equals "Natural value with multiple leading zeros (000031)" [util::trim_leading_zeros 000031] {31}
    aa_equals "Natural value already trimmed (31)" [util::trim_leading_zeros 31] {31}
    aa_equals "String (0asfda)" [util::trim_leading_zeros 0asfda] {asfda}
    aa_equals "String with multiple leading zeros (000asfda)" [util::trim_leading_zeros 000asfda] {asfda}
    aa_equals "String already trimmed (asfda)" [util::trim_leading_zeros asfda] {asfda}
    aa_equals "Only zeros (000)" [util::trim_leading_zeros 000] {0}
    aa_equals "Only one zero (0)" [util::trim_leading_zeros 0] {0}
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util_absolute_path_p \
    util__absolute_path_p {

        Test util_absolute_path_p

        @creation-date 2018-09-17
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    foreach path {
        ""
        "blablabla"
        "bla/bla/bla/"
    } {
        aa_false $path [util_absolute_path_p $path]
    }
    foreach path {
        "/"
        "/blablabla"
        "/bla/bla/bla/"
    } {
        aa_true $path [util_absolute_path_p $path]
    }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util_complete_url_p \
    util__complete_url_p {

        Test util_complete_url_p

        @creation-date 2018-09-17
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    foreach url {
        ""
        "/test"
        ":/test"
    } {
        aa_false $url [util_complete_url_p $url]
    }
    foreach url {
        "http://test"
        "ftp://test"
    } {
        aa_true $url [util_complete_url_p $url]
    }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util_commify_number \
    util__commify_number {

        Test util_commify_number

        @creation-date 2018-09-18
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    aa_equals "Empty value" [util_commify_number {}] {}
    aa_equals "0" [util_commify_number 0] {0}
    aa_equals "0.0" [util_commify_number 0.0] {0.0}
    aa_equals ".0" [util_commify_number .0] {.0}
    aa_equals "100" [util_commify_number 100] {100}
    aa_equals "1000" [util_commify_number 1000] {1,000}
    aa_equals "1000000" [util_commify_number 1000000] {1,000,000}
    aa_equals "1000000000" [util_commify_number 1000000000] {1,000,000,000}
    aa_equals "1000000000.0002340" [util_commify_number 1000000000.0002340] {1,000,000,000.0002340}
    aa_equals "-0" [util_commify_number -0] {-0}
    aa_equals "-.0" [util_commify_number -.0] {-.0}
    aa_equals "-.0000" [util_commify_number -.0000] {-.0000}
    aa_equals "-100" [util_commify_number -100] {-100}
    aa_equals "-1000" [util_commify_number -1000] {-1,000}
    aa_equals "-1000000" [util_commify_number -1000000] {-1,000,000}
    aa_equals "-1000000000" [util_commify_number -1000000000] {-1,000,000,000}
    aa_equals "-1000000000.0002340" [util_commify_number -1000000000.0002340] {-1,000,000,000.0002340}
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util_escape_quotes_for_csv \
    util__escape_quotes_for_csv {

        Test util_escape_quotes_for_csv

        @creation-date 2018-09-18
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    aa_equals "Empty value" [util_escape_quotes_for_csv {}] {}
    aa_equals "\"\"" [util_escape_quotes_for_csv {""}] {\"\"}
    aa_equals "Test \" \" test" [util_escape_quotes_for_csv {Test " " test}] {Test \" \" test}
    aa_equals "\"Test\"" [util_escape_quotes_for_csv {"Test"}] {\"Test\"}
    aa_equals "\"Test test test\"" [util_escape_quotes_for_csv {"Test test test"}] {\"Test test test\"}
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        util::min
        util::max
    } \
    min_max {

        Test util::min and util::max procs

        @creation-date 2018-09-18
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    aa_equals "Empty value" [util::min {}] {}
    aa_equals "Empty value" [util::max {}] {}
    aa_equals "1" [util::min 1] {1}
    aa_equals "1" [util::max 1] {1}
    aa_equals "1 0 -1" [util::min 1 0 -2] {-2}
    aa_equals "1 0 -1" [util::max 1 0 -2] {1}
    aa_equals "0 0.89 -0.89 -1" [util::min 0 0.89 -0.89 -1] {-1}
    aa_equals "0 0.89 -0.89 -1" [util::max 0 0.89 -0.89 -1] {0.89}
    aa_equals "3 1000 0 -3 -2000" [util::min 3 1000 0 -3 -2000] {-2000}
    aa_equals "3 1000 0 -3 -2000" [util::max 3 1000 0 -3 -2000] {1000}
    aa_log "List with numeric and non-numeric entries"
    aa_equals "1 2 z a boy 6" [util::max 1 2 z a boy 6] z
    aa_equals "1 2 z a boy 6" [util::min 1 2 z a boy 6] 1
    aa_log "List with some weird entries"
    aa_equals "1 -0.4 -0,4 -1000 2 @ z a b 6" [util::max 1 -0.4 -0,4 -1000 2 @ z a b 6] z
    aa_equals "1 -0.4 -0,4 -1000 2 @ z a b 6" [util::min 1 -0.4 -0,4 -1000 2 @ z a b 6] -0,4
}

aa_register_case \
    -cats {api} \
    -procs util_url_valid_p \
    acs_tcl__util_url_valid_p {
    A very rudimentary test of util_url_valid_p

    @creation-date 2004-01-10
    @author Branimir Dolicki (bdolicki@branimir.com)
} {
    foreach url {
        "http://example.com"
        "https://example.com"
        "ftp://example.com"
        "http://example.com/"
        "HTTP://example.com"
        "http://example.com/foo/bar/blah"
        "http://example.com?foo=bar&bar=foo"
    } {
        aa_true "Valid web URL $url" [util_url_valid_p "$url"]
    }
    foreach url {
        "xhttp://example.com"
        "httpx://example.com"
        "wysiwyg://example.com"
        "mailto:joe@example.com"
        "foo"
        "/foo/bar"
    } {
        aa_false "Invalid web URL $url" [util_url_valid_p "$url"]
    }
}


aa_register_case \
    -cats {web smoke} \
    -procs {
        acs::test::http
        acs::test::reply_has_status_code
        site_node::get_from_url
    } front_page_1 {

    } {
    set d [acs::test::http -depth 3 /]
    set main_node [site_node::get_from_url -url "/"]
    acs::test::reply_has_status_code $d 200
}

aa_register_case \
    -cats {smoke api} \
    -procs {
        util::age_pretty
    } util__age_pretty {
        Test the util::age_pretty proc.
} {
    aa_log "Forcing locale to en_US for all strings so that tests work in any locale"
    aa_equals "0 secs"       [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:00" -locale en_US] "1 minute ago"
    aa_equals "1 sec"        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:01" -locale en_US] "1 minute ago"
    aa_equals "29 secs"      [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:29" -locale en_US] "1 minute ago"
    aa_equals "30 secs"      [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:30" -locale en_US] "1 minute ago"
    aa_equals "31 secs"      [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:31" -locale en_US] "1 minute ago"
    aa_equals "59 secs"      [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:59" -locale en_US] "1 minute ago"
    aa_equals "1 min"        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:01:00" -locale en_US] "1 minute ago"
    aa_equals "1 min 1 sec"  [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:01:01" -locale en_US] "1 minute ago"

    aa_equals "1 min 29 sec" [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:01:29" -locale en_US] "1 minute ago"
    aa_equals "1 min 30 sec" [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:01:30" -locale en_US] "2 minutes ago"
    aa_equals "1 min 31 sec" [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:01:31" -locale en_US] "2 minutes ago"

    aa_equals "11 hours 59 minutes" [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-01 23:59:00" -locale en_US] "11 hours 59 minutes ago"
    aa_equals "15 hours 0 minutes with override" \
        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-02 03:00:00" -hours_limit 16 -locale en_US] "15 hours ago"


    aa_equals "12 hours 0 minutes" [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-02 00:00:00" -locale en_US] "12:00 PM, Thursday"

    aa_equals "15 hours 0 minutes" [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-02 03:00:00" -locale en_US] "12:00 PM, Thursday"

    aa_equals "4 days 0 hours 0 minutes with override" \
        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-05 12:00:00" -days_limit 5 -locale en_US] "12:00 PM, Thursday"

    aa_equals "3 days 0 hours 0 minutes" \
        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-04 12:00:00" -locale en_US] "12:00 PM, 01 Jan 2004"

    aa_equals "5 days 0 hours 0 minutes" \
        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2004-01-06 12:00:00" -locale en_US] "12:00 PM, 01 Jan 2004"

    aa_equals "10 years" \
        [util::age_pretty -timestamp_ansi "2004-01-01 12:00:00" -sysdate_ansi "2014-01-01 12:00:00" -locale en_US] "12:00 PM, 01 Jan 2004"

    aa_log "100 years - we know it's wrong because of Tcl library limitations: [util::age_pretty -timestamp_ansi "1904-01-01 12:00:00" -sysdate_ansi "2004-01-01 12:00:00"]"
}


aa_register_case -cats {api} \
    -bugs 1450 \
    -procs {
        ad_enhanced_text_to_html
    } \
    ad_enhanced_text_to_html {

        Process sample text correctly
        @author Nima Mazloumi
} {

    set string_with_img {<img src="http://test.test/foo.png">}
    aa_log "Original string is [ns_quotehtml $string_with_img]"
    set html_version [ad_enhanced_text_to_html $string_with_img]
    aa_true "new: [ns_quotehtml $html_version] should be the same" {$html_version eq $string_with_img}

    set text {http://www.mail-archive.com/aolserver-talk@lists.sourceforge.net/msg00277.html}
    aa_log "Original string is with @-sign: [ns_quotehtml $text]"
    set html {<a href="http://www.mail-archive.com/aolserver-talk@lists.sourceforge.net/msg00277.html">http://www.mail-archive.com/aolserver-talk@lists.sourceforge.net/msg00277.html</a>}
    aa_true "link with @-sign should not contain mailto:link" {[ad_enhanced_text_to_html $text] eq $html}

}


aa_register_case \
    -cats {api smoke} \
    -procs acs_object::package_id \
    acs_object__package_id {
        Tests the acs_object__package_id procedure

        @author Malte Sussdorff
} {
    # Retrieve an objects_package_id
    set object_id [db_string get_object_id "select max(object_id) from acs_objects where package_id >0"]
    set package_id [db_string get_package_id "select package_id from acs_objects where object_id = :object_id"]
    aa_equals "package_id returned is correct" $package_id [acs_object::package_id -object_id $object_id]
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_user::registered_user_p
        acs_user::approve
        acs_user::ban

        db_1row
    } \
    acs_user__registered_user_p {
        Tests the acs_user::registered_user_p procedure

        @author Malte Sussdorff
} {
    # Retrieve a registered user
    set user_id [db_string get_registered_id {select max(user_id) from registered_users}]

    # Check if the registered_user_p procedure finds him
    set is_registered_p [acs_user::registered_user_p -user_id $user_id]

    # Ban the user and check if he is not a registered_user anymore
    acs_user::ban -user_id $user_id
    set is_not_registered_p [acs_user::registered_user_p -user_id $user_id]

    set works_p [expr {$is_registered_p && !$is_not_registered_p}]

    acs_user::approve -user_id $user_id
    aa_true "registered_user_p works correct" $works_p
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_user::ban
        acs_user::approve
        acs_user::registered_user_p

        db_1row
    } \
    acs_user__ban_approve {
        Tests the acs_user::ban and acs_user::approve procs

        @author Héctor Romojaro <hector.romojaro.gomez@wu.ac.at>
        @creation-date 2019-09-02
} {
    # Retrieve a registered user
    set user_id [db_string get_registered_id {select max(user_id) from registered_users}]

    # Ban and approve the user and check
    aa_true "User is registered" [acs_user::registered_user_p -user_id $user_id]
    acs_user::ban -user_id $user_id
    aa_false "User banned" [acs_user::registered_user_p -user_id $user_id]
    acs_user::approve -user_id $user_id
    aa_true "User approved" [acs_user::registered_user_p -user_id $user_id]
}

aa_register_case \
    -cats {api smoke} \
    -procs ns_parseurl \
    util__ns_parseurl {
        Test ns_parseurl

        @author Gustaf Neumann
} {
    aa_equals "full url, no port" \
        [ns_parseurl http://openacs.org/www/t.html] \
        {proto http host openacs.org path www tail t.html}

    aa_equals "full url, with port" \
        [ns_parseurl http://openacs.org:80/www/t.html] \
        {proto http host openacs.org port 80 path www tail t.html}

    aa_equals "full url, no port, no component" \
        [ns_parseurl http://openacs.org/] \
        {proto http host openacs.org path {} tail {}}

    aa_equals "full url, no port, no component, no trailing slash" \
        [ns_parseurl http://openacs.org] \
        {proto http host openacs.org path {} tail {}}

    aa_equals "full url, no port, one component" \
        [ns_parseurl http://openacs.org/t.html] \
        {proto http host openacs.org path {} tail t.html}

    #
    # relative URLs
    #
    aa_equals "relative url" \
        [ns_parseurl /www/t.html] \
        {path www tail t.html}

    # legacy NaviServer for pre HTTP/1.0, desired?

    aa_equals "legacy NaviServer, pre HTTP/1.0, no leading /" \
        [ns_parseurl www/t.html] \
        {tail www/t.html}

    #
    # protocol relative (protocol agnostic) URLs (contained in RFC 3986)
    #
    aa_equals "protocol relative url with port" \
        [ns_parseurl //openacs.org/www/t.html] \
        {host openacs.org path www tail t.html}

    aa_equals "protocol relative url without port" \
        [ns_parseurl //openacs.org:80/www/t.html] \
        {host openacs.org port 80 path www tail t.html}
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs ad_decode \
    ad_decode {

        Test the ad_decode proc

        @author Hanifa Hasan
} {
    set cases {1 one 2 two 3 three 4 four 5 five 546356 423654 sdgvlrjnevclme sdlgtmsdgvsdf}
    set cases_complete [concat $cases "Unknown"]
    dict for {case result} $cases {
        aa_equals "ad_decode $case $cases_complete return $result" "$result" [ad_decode $case {*}$cases_complete]
    }
    aa_equals "ad_decode gibberish $cases_complete return Unknown" "Unknown" [ad_decode gibberish {*}$cases_complete]
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs util::interval_pretty \
    util__interval_pretty {

        Test the util::interval_pretty proc

        @author Hanifa Hasan
} {
    set convert_seconds {6344 "1h 45m 44s" 433 "7m 13s" 5556 "1h 32m 36s" 234 "3m 54s" 23 "23s" 604800 "168h 0m 0s"}
    dict for {seconds result} $convert_seconds {
        aa_true "util::interval_pretty $seconds return $result " {[util::interval_pretty -seconds $seconds] eq $result }
    }
    aa_equals "Empty seconds" [util::interval_pretty -seconds ""] ""
    aa_equals "No arguments" [util::interval_pretty] ""
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
