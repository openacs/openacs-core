ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the acs-tcl package.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 22 January 2003
}

ad_proc apm_test_callback_file_path {} {
    The path of the test file used to check that the callback proc executed ok.
} {
    return "[acs_package_root_dir acs-tcl]/tcl/test/callback_proc_test_file"
}

ad_proc apm_test_callback_proc {
    {-arg1:required}
    {-arg2:required}
} {
    # Write something to a file so that can check that the proc executed
    set file_path [apm_test_callback_file_path]
    set file_id [open $file_path w]
    puts $file_id "$arg1 $arg2"
    close $file_id
}


aa_register_case util__sets_equal_p {
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

aa_register_case apm__test_info_file {
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
    if { [empty_string_p $auto_mount] } {
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
    
        # Read the xml file
        array set spec_array [apm_read_package_info_file $spec_path]
    
        # Assert that info parsed from xml file is correct
        array set parsed_callback_array $spec_array(callbacks)
    
        aa_true "Only one permissible callback should be returned, got array [array get parsed_callback_array]" \
                [expr [llength [array names parsed_callback_array]] == 1]
    
        aa_equals "Checking name of callback of allowed type $allowed_type" \
                $parsed_callback_array($allowed_type) $callback_array($allowed_type)

        aa_equals "Checking that auto-callback is correct" $spec_array(auto-mount) $auto_mount
            
    } error]

    # Teardown
    file delete $spec_path
    foreach {type proc} [array get callback_array] {
      db_dml remove_callback {delete from apm_package_callbacks 
                              where version_id = :version_id
                              and type = :type }
    }
    db_dml reset_auto_mount {update apm_package_versions
                             set auto_mount = :auto_mount_orig
                             where version_id = :version_id}


    if { $error_p } {
        global errorInfo
        error "$error - $errorInfo"
    }
}

aa_register_case apm__test_callback_get_set {
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
        global errorInfo
        error "$error - $errorInfo"
    }
}

aa_register_case apm__test_callback_invoke {
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
    file delete $file_path
    apm_remove_callback_proc -package_key $package_key -type $type

    if { $error_p } {
        global errorInfo
        error "$error - $errorInfo"
    }
}

aa_register_case xml_get_child_node_content_by_path {
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
        [xml_get_child_node_content_by_path $root_node { { person commments foo } { person name first_names } { properties datetime } }] "2001-08-08"


}

aa_register_case -cats {
    script
} -on_error {
    site_node::get_children returns root node!
} site_node_get_children {
    Test site_node::get_children
} {
    # Start with a known site-map entry
    set node_id [site_node::get_node_id -url "/"]

    set child_node_ids [site_node::get_children \
			    -all \
			    -element node_id \
			    -node_id $node_id]

    # lsearch returns '-1' if not found
    aa_equals "site_node::get_children does not return root node" [lsearch -exact $child_node_ids $node_id] -1


    # -package_key
    set nodes [site_node::get_children -all -element node_id -node_id $node_id -filter_element package_key -filter_value "acs-admin"]

    aa_equals "package_key arg. identical to filter_element package_key" \
        [site_node::get_children -all -element node_id -node_id $node_id -package_key "acs-admin"] \
        $nodes
    
    aa_equals "Found exactly one acs-admin node" [llength $nodes] 1


    # -package_type
    set nodes [site_node::get_children -all -element node_id -node_id $node_id -filter_element package_type -filter_value "apm_service"]
    aa_equals "package_type arg. identical to filter_element package_type" \
        [site_node::get_children -all -element node_id -node_id $node_id -package_type "apm_service"] \
        $nodes
    
    aa_true "Found at least one apm_service node" [expr [llength $nodes] > 0]

    # nonexistent package_type
    aa_true "No nodes with package type 'foo'" \
        [expr [llength [site_node::get_children -all -element node_id -node_id $node_id -package_type "foo"]] == 0]

    
}

