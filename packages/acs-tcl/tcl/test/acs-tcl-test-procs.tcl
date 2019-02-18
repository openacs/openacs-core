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
        apm_generate_package_spec
        apm_read_package_info_file
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

        # Read the xml file
        array set spec_array [apm_read_package_info_file $spec_path]

        # Assert that info parsed from xml file is correct
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
    -procs apm_invoke_callback_proc \
    apm__test_callback_invoke {
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
    -procs xml_get_child_node_content_by_path \
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
    -cats {api} \
    -procs {
        site_node::get_children
        site_node::get_node_id
    } \
    -on_error {
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
    set nodes [site_node::get_children -all -element node_id -node_id $node_id -filters { package_key "acs-admin" }]

    aa_equals "package_key arg. identical to -filters" \
        [site_node::get_children -all -element node_id -node_id $node_id -package_key "acs-admin"] \
        $nodes

    aa_equals "Found exactly one acs-admin node" [llength $nodes] 1


    # -package_type
    set nodes [site_node::get_children -all -element node_id -node_id $node_id -filters { package_type "apm_service" }]
    aa_equals "package_type arg. identical to filter_element package_type" \
        [site_node::get_children -all -element node_id -node_id $node_id -package_type "apm_service"] \
        $nodes

    aa_true "Found at least one apm_service node" {[llength $nodes] > 0}

    # nonexistent package_type
    aa_true "No nodes with package type 'foo'" \
        {[llength [site_node::get_children -all -element node_id -node_id $node_id -package_type "foo"]] == 0}


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
I have a dynamically assigned ip address, so I use dyndns.org to
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
    -procs ad_page_contract_filter_invoke \
    ad_page_contract_filters {
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
    -procs export_vars \
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
    -cats {api db smoke} \
    -procs db_transaction \
    db__transaction {
        Test db_transaction
} {

    # create a temp table for testing
    catch {db_dml remove_table {drop table tmp_db_transaction_test}}
    db_dml new_table {create table tmp_db_transaction_test (a integer constraint tmp_db_transaction_test_pk primary key, b integer)}


    aa_equals "Test we can insert a row in a db_transaction clause" \
        [catch {db_transaction {db_dml test1 {insert into tmp_db_transaction_test(a,b) values (1,2)}}}] 0

    aa_equals "Verify clean insert worked" \
        [db_string check1 {select a from tmp_db_transaction_test} -default missing] 1

    # verify the on_error clause is called
    set error_called 0
    catch {db_transaction { set foo } on_error {set error_called 1}} errMsg
    aa_equals "error clause invoked on Tcl error" \
        $error_called 1

    # Check that the Tcl error propagates up from the code block
    set error_p [catch {db_transaction { error "BAD CODE"}} errMsg]
    aa_equals "Tcl error propagates to errMsg from code block" \
        $errMsg "Transaction aborted: BAD CODE"

    # Check that the Tcl error propagates up from the on_error block
    set error_p [catch {db_transaction {set foo} on_error { error "BAD CODE"}} errMsg]
    aa_equals "Tcl error propagates to errMsg from on_error block" \
        $errMsg "BAD CODE"


    # check a dup insert fails and the primary key constraint comes back in the error message.
    set error_p [catch {db_transaction {db_dml test2 {insert into tmp_db_transaction_test(a,b) values (1,2)}}} errMsg]
    aa_true "error thrown inserting duplicate row" $error_p
    aa_true "error message contains constraint violated" [string match -nocase {*tmp_db_transaction_test_pk*} $errMsg]

    # check a sql error calls on_error clause
    set error_called 0
    set error_p [catch {db_transaction {db_dml test3 {insert into tmp_db_transaction_test(a,b) values (1,2)}} on_error {set error_called 1}} errMsg]
    aa_false "no error thrown with on_error clause" $error_p
    aa_equals "error message empty with on_error clause" \
        $errMsg {}

    # Check on explicit aborts
    set error_p [catch {
        db_transaction {
            db_dml test4 {
                insert into tmp_db_transaction_test(a,b) values (2,3)
            }
            db_abort_transaction
        }
    } errMsg]
    aa_true "error thrown with explicit abort" $error_p
    aa_equals "row not inserted with explicit abort" \
        [db_string check4 {select a from tmp_db_transaction_test where a = 2} -default missing] "missing"

    # Check a failed sql command can do sql in the on_error block
    set sqlok {}
    set error_p [catch {
        db_transaction {
            db_dml test5 {
                insert into tmp_db_transaction_test(a,b) values (1,2)
            }
        } on_error {
            set sqlok [db_string check5 {select a from tmp_db_transaction_test where a = 1}]
        }
    } errMsg]
    aa_false "No error thrown doing sql in on_error block" $error_p
    aa_equals "Query succeeds in on_error block" \
        $sqlok 1


    # Check a failed transactions dml is rolled back in the on_error block
    set error_p [catch {
        db_transaction {
            error "BAD CODE"
        } on_error {
            db_dml test6 {
                insert into tmp_db_transaction_test(a,b) values (3,4)
            }
        }
    } errMsg]
    aa_false "No error thrown doing insert dml in on_error block" $error_p
    aa_equals "Insert in on_error block rolled back, code error" \
        [db_string check6 {select a from tmp_db_transaction_test where a = 3} -default {missing}] missing


    # Check a failed transactions dml is rolled back in the on_error block
    set error_p [catch {
        db_transaction {
            db_dml test7 {
                insert into tmp_db_transaction_test(a,b) values (1,2)
            }
        } on_error {
            db_dml test8 {
                insert into tmp_db_transaction_test(a,b) values (3,4)
            }
        }
    } errMsg]
    aa_false "No error thrown doing insert dml in on_error block" $error_p
    aa_equals "Insert in on_error block rolled back, sql error" \
        [db_string check8 {select a from tmp_db_transaction_test where a = 3} -default {missing}] missing



    # check nested db_transactions work properly with clean code
    set error_p [catch {
        db_transaction {
            db_dml test9 {
                insert into tmp_db_transaction_test(a,b) values (5,6)
            }
            db_transaction {
                db_dml test10 {
                    insert into tmp_db_transaction_test(a,b) values (6,7)
                }
            }
        }
    } errMsg]
    aa_false "No error thrown doing nested db_transactions" $error_p
    aa_equals "Data inserted in  outer db_transaction" \
        [db_string check9 {select a from tmp_db_transaction_test where a = 5} -default {missing}] 5
    aa_equals "Data inserted in nested db_transaction" \
        [db_string check10 {select a from tmp_db_transaction_test where a = 6} -default {missing}] 6



    # check error in outer transaction rolls back nested transaction
    set error_p [catch {
        db_transaction {
            db_dml test11 {
                insert into tmp_db_transaction_test(a,b) values (7,8)
            }
            db_transaction {
                db_dml test12 {
                    insert into tmp_db_transaction_test(a,b) values (8,9)
                }
            }
            error "BAD CODE"
        }
    } errMsg]
    aa_true "Error thrown doing nested db_transactions" $error_p
    aa_equals "Data rolled back in outer db_transactions with error in outer" \
        [db_string check11 {select a from tmp_db_transaction_test where a = 7} -default {missing}] missing
    aa_equals "Data rolled back in nested db_transactions with error in outer" \
        [db_string check12 {select a from tmp_db_transaction_test where a = 8} -default {missing}] missing

    # check error in outer transaction rolls back nested transaction
    set error_p [catch {
        db_transaction {
            db_dml test13 {
                insert into tmp_db_transaction_test(a,b) values (9,10)
            }
            db_transaction {
                db_dml test14 {
                    insert into tmp_db_transaction_test(a,b) values (10,11)
                }
                error "BAD CODE"
            }
        }
    } errMsg]
    aa_true "Error thrown doing nested db_transactions: $errMsg" $error_p
    aa_equals "Data rolled back in outer db_transactions with error in nested" \
        [db_string check13 {select a from tmp_db_transaction_test where a = 9} -default {missing}] missing
    aa_equals "Data rolled back in nested db_transactions with error in nested" \
        [db_string check14 {select a from tmp_db_transaction_test where a = 10} -default {missing}] missing

    db_dml drop_table {drop table tmp_db_transaction_test}
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
    -procs util::randomize_list \
    util__randomize_list {
        Test util::randomize_list
} {
    aa_equals "Empty list" [util::randomize_list {}] {}

    aa_equals "One-element list" [util::randomize_list {a}] {a}

    aa_true "Two-element list" [util_sets_equal_p [list a b] [util::randomize_list [list a b]]]

    set org_list [list a b c d e f g h i j]
    set randomized_list [util::randomize_list $org_list]
    aa_true "Ten-element list: $randomized_list" [util_sets_equal_p $org_list $randomized_list]

    set len [randomRange 200]
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
    aa_equals "Real value with multiple leading zeroes (000.31)" [util::trim_leading_zeros 0000.31] {.31}
    aa_equals "Real value already trimmed (.31)" [util::trim_leading_zeros .31] {.31}
    aa_equals "Natural value (031)" [util::trim_leading_zeros 031] {31}
    aa_equals "Natural value with multiple leading zeroes (000031)" [util::trim_leading_zeros 000031] {31}
    aa_equals "Natural value already trimmed (31)" [util::trim_leading_zeros 31] {31}
    aa_equals "String (0asfda)" [util::trim_leading_zeros 0asfda] {asfda}
    aa_equals "String with multiple leading zeroes (000asfda)" [util::trim_leading_zeros 000asfda] {asfda}
    aa_equals "String already trimmed (asfda)" [util::trim_leading_zeros asfda] {asfda}
    aa_equals "Only zeroes (000)" [util::trim_leading_zeros 000] {0}
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
        min
        max
    } \
    min_max {

        Test min and max procs

        @creation-date 2018-09-18
        @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    aa_equals "Empty value" [min {}] {}
    aa_equals "Empty value" [max {}] {}
    aa_equals "1" [min 1] {1}
    aa_equals "1" [max 1] {1}
    aa_equals "1 0 -1" [min 1 0 -2] {-2}
    aa_equals "1 0 -1" [max 1 0 -2] {1}
    aa_equals "0 0.89 -0.89 -1" [min 0 0.89 -0.89 -1] {-1}
    aa_equals "0 0.89 -0.89 -1" [max 0 0.89 -0.89 -1] {0.89}
    aa_equals "3 1000 0 -3 -2000" [min 3 1000 0 -3 -2000] {-2000}
    aa_equals "3 1000 0 -3 -2000" [max 3 1000 0 -3 -2000] {1000}
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
    front_page_1 {

} {
    set d [acs::test::http /]
    set main_node [site_node::get_from_url -url "/"]
    acs::test::reply_contains $d [::lang::util::localize [dict get $main_node instance_name]]
}

aa_register_case \
    -cats {smoke api} \
    -procs util::age_pretty \
    util__age_pretty {
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

aa_register_case \
    -procs db_get_quote_indices \
    -cats {api} \
    db_get_quote_indices {
        Test the proc db_get_quote_indices.

        @author Peter Marklund
} {
    aa_equals "" [db_get_quote_indices {'a'}] {0 2}
    aa_equals "" [db_get_quote_indices {'a''}] {}
    aa_equals "" [db_get_quote_indices {'a'a'a'}] {0 2 4 6}
    aa_equals "" [db_get_quote_indices {a'b'c'd''s'}] {1 3 5 10}
    aa_equals "" [db_get_quote_indices {'}] {}
    aa_equals "" [db_get_quote_indices {''}] {}
    aa_equals "" [db_get_quote_indices {a''a}] {}
    aa_equals "" [db_get_quote_indices {a'b'a}] {1 3}
    aa_equals "" [db_get_quote_indices {'a''b'}] {0 5}
}

aa_register_case \
    -procs db_bind_var_substitution \
    -cats {api} \
    db_bind_var_substitution {
        Test the proc db_bind_var_substitution.

        @author Peter Marklund
} {

    # DRB: Not all of these test cases work for Oracle (select can't be used in
    # db_exec_plsql) and bindvar substitution is done by Oracle, not the driver,
    # anyway so there's not much point in testing.   These tests really test
    # Oracle bindvar emulation, in other words...

    if { [db_type] ne "oracle" } {
        set sql {to_char(fm.posting_date, 'YYYY-MM-DD HH24:MI:SS')}
        aa_equals "don't subst bind vars in quoted date" [db_bind_var_substitution $sql {SS 3 MI 4}] $sql

        set sql {to_char(fm.posting_date, :SS)}
        aa_equals "don't subst bind vars in quoted date" [db_bind_var_substitution $sql {SS 3 MI 4}] {to_char(fm.posting_date, '3')}

        set sql {to_char(fm.posting_date, don''t subst ':SS', do subst :SS )}
        aa_equals "don't subst bind vars in quoted date" [db_bind_var_substitution $sql {SS 3 MI 4}] {to_char(fm.posting_date, don''t subst ':SS', do subst '3' )}


        set SS 3
        set db_value [db_exec_plsql test_bind {
            select ':SS'
        }]
        aa_equals "db_exec_plsql should not bind quoted var" $db_value ":SS"

        set db_value [db_exec_plsql test_bind {
            select :SS
        }]
        aa_equals "db_exec_plsql bind not quoted var" $db_value "3"
    }
}

aa_register_case -cats {api} \
    -bugs 1450 \
    -procs ad_enhanced_text_to_html \
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
    -cats {db smoke production_safe} \
    -procs {db_foreach} \
    db__db_foreach {
        Checks that db_foreach works as expected
    } {
        set results [list]
        db_foreach query {SELECT a FROM (VALUES (1), (2), (3), (4), (5), (6), (7)) AS X(a)} {
            lappend results $a
        }
        aa_equals "db_foreach collects correct values from query" \
            [list 1 2 3 4 5 6 7] \
            $results

        set results ""
        db_foreach query {select 1 from dual where 1 = 2} {
            set results "found"
        } else {
            set results "not found"
        }
        aa_equals "db_foreach executes the 'no row' code block using the 'else' syntax" \
            "not found" \
            $results

        set results ""
        db_foreach query {select 1 from dual where 1 = 2} {
            set results "found"
        } if_no_rows {
            set results "not found"
        }
        aa_equals "db_foreach executes the 'no row' code block using the 'if_no_rows' syntax" \
            "not found" \
            $results
    }

aa_register_case -cats {api db} db__caching {
    test db_* API caching
} {

    # Check db_string caching

    # Check that cached and non-cached calls return the same value.  We need to
    # check the caching API call twice, once to fill the cache and return the
    # value, and again to see that the call returns the proper value from the
    # cache.  This series ends by testing the flushing of db_cache_pool with an
    # exact pattern.

    set not_cached \
        [db_string test1 {select first_names from persons where person_id = 0}]
    aa_equals "Test that caching and non-caching db_string call return same result" \
        [db_string -cache_key test1 test1 {select first_names from persons where person_id = 0}] \
        $not_cached
    aa_true "Test1 cached value found." \
        ![catch {ns_cache get db_cache_pool test1} errmsg]
    aa_equals "Test that cached db_string returns the right value from the cache" \
        [db_string -cache_key test1 test1 {select first_names from persons where person_id = 0}] \
        $not_cached
    db_flush_cache -cache_key_pattern test1
    aa_true "Flush of test1 from cache using the exact key" \
        [catch {ns_cache get db_cache_pool test1} errmsg]

    # Check that cached and non-cached calls return the same default if no value
    # is returned by the query.  This series ends by testing the flushing of the
    # entire db_cache_pool cache.

    set not_cached \
        [db_string test2 {select first_names from persons where person_id=1 and person_id=2} \
            -default foo]
    aa_equals "Test that caching and non-caching db_string call return same default value" \
        [db_string -cache_key test2 test2 {select first_names from persons where person_id=1 and person_id=2} \
            -default foo] \
        $not_cached
    aa_true "Test2 cached value found." \
        ![catch {ns_cache get db_cache_pool test2} errmsg]
    aa_equals "Test that caching and non-caching db_string call return same default value" \
        [db_string -cache_key test2 test2 {select first_names from persons where person_id=1 and person_id=2} \
            -default foo] \
        $not_cached
    db_flush_cache
    aa_true "Flush of test2 by flushing entire pool" \
        [catch {ns_cache get db_cache_pool test2} errmsg]

    # Check that cached and non-cached calls return an error if the query returns
    # no data and no default is supplied.  This series ends by testing cache flushing
    # by "string match" pattern.

    aa_true "Uncached db_string call returns error if query returns no data" \
        [catch {db_string test3 "select first_names from persons where person_id=1 and person_id=2"}]
    aa_true "Cached db_string call returns error if query returns no data" \
        [catch {db_string -cache_key test3 test3 "select first_names from persons where person_id=1 and person_id=2"}]
    aa_true "db_string call returns error if caching call returned error" \
        [catch {db_string -cache_key test3 test3 "select first_names from persons where person_id=1 and person_id=2"}]
    db_flush_cache -cache_key_pattern tes*3
    aa_true "Flush of test3 from cache using pattern" \
        [catch {ns_cache get db_cache_pool test3} errmsg]

    # Check db_list caching

    set not_cached \
        [db_list test4 {select first_names from persons where person_id = 0}]
    aa_equals "Test that caching and non-caching db_list call return same result" \
        [db_list -cache_key test4 test4 {select first_names from persons where person_id = 0}] \
        $not_cached
    aa_true "Test4 cached value found." \
        ![catch {ns_cache get db_cache_pool test4} errmsg]
    aa_equals "Test that cached db_list returns the right value from the cache" \
        [db_list -cache_key test4 test4 {select first_names from persons where person_id = 0}] \
        $not_cached
    db_flush_cache

    # Check db_list_of_lists caching

    set not_cached \
        [db_list_of_lists test5 {select * from persons where person_id = 0}]
    aa_equals "Test that caching and non-caching db_list_of_lists call return same result" \
        [db_list_of_lists -cache_key test5 test5 {select * from persons where person_id = 0}] \
        $not_cached
    aa_true "Test5 cached value found." \
        ![catch {ns_cache get db_cache_pool test5} errmsg]
    aa_equals "Test that cached db_list_of_lists returns the right value from the cache" \
        [db_list_of_lists -cache_key test5 test5 {select * from persons where person_id = 0}] \
        $not_cached
    db_flush_cache

    # Check db_multirow caching

    db_multirow test6 test6 {select * from persons where person_id = 0}
    set not_cached \
        [list test6:rowcount test6:columns [array get test6:1]]
    db_multirow -cache_key test6 test6 test6 {select * from persons where person_id = 0}
    set cached \
        [list test6:rowcount test6:columns [array get test6:1]]
    aa_equals "Test that caching and non-caching db_multirow call return same result" \
        $cached $not_cached
    aa_true "Test6 cached value found." \
        ![catch {ns_cache get db_cache_pool test6} errmsg]
    db_multirow -cache_key test6 test6 test6 {select * from persons where person_id = 0}
    set cached \
        [list test6:rowcount test6:columns [array get test6:1]]
    aa_equals "Test that cached db_multirow returns the right value from the cache" \
        $cached $not_cached
    db_flush_cache

    # Check db_0or1row caching

    set not_cached \
       [db_0or1row test7 {select * from persons where person_id = 0} -column_array test7]
    lappend not_cached [array get test7]
    set cached \
        [db_0or1row -cache_key test7 test7 {select * from persons where person_id = 0} -column_array test7]
    lappend cached [array get test7]
    aa_equals "Test that caching and non-caching db_0or1row call return same result for 1 row" \
        $cached $not_cached
    aa_true "Test7 cached value found." \
        ![catch {ns_cache get db_cache_pool test7} errmsg]
    set cached \
        [db_0or1row -cache_key test7 test7 {select * from persons where person_id = 0} -column_array test7]
    lappend cached [array get test7]
    aa_equals "Test that cached db_0or1row returns the right value from the cache for 1 row" \
        $cached $not_cached
    db_flush_cache

    # Check db_0or1row caching returns 0 if query returns no values

    set not_cached \
       [db_0or1row test8 {select * from persons where person_id=1 and person_id=2} -column_array test8]
    set cached \
        [db_0or1row -cache_key test8 test8 {select * from persons where person_id=1 and person_id=2} -column_array test8]
    aa_equals "Test that caching and non-caching db_0or1row call return same result for 0 rows" \
        $cached $not_cached
    aa_true "Test8 cached value found." \
        ![catch {ns_cache get db_cache_pool test8} errmsg]
    set cached \
        [db_0or1row -cache_key test8 test8 {select * from persons where person_id=1 and person_id=2} -column_array test8]
    aa_equals "Test that cached db_0or1row returns the right value from the cache for 0 rows" \
        $cached $not_cached
    db_flush_cache

    # Won't check db_1row because it just calls db_0or1row

}


aa_register_case \
    -cats {api smoke} \
    -procs {
        parameter::get parameter::get_from_package_key
        parameter::set_default parameter::set_default
        parameter::set_value parameter::set_from_package_key
        parameter::set_global_value parameter::get_global_value
    } \
    parameter__check_procs {
        Test the parameter::* procs

        @author Rocael Hernandez (roc@viaro.net)
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            aa_log "Test global parameter functionality"
            set parameter_id [db_nextval "acs_object_id_seq"]
            apm_parameter_register -parameter_id $parameter_id -scope global x_test_x "" acs-tcl 0 number
            parameter::set_global_value -package_key acs-tcl -parameter x_test_x -value 3
            aa_equals "check global parameter value set/get" \
                [parameter::get_global_value -package_key acs-tcl -parameter x_test_x] \
                "3"
            apm_parameter_unregister $parameter_id

            foreach tuple [db_list_of_lists get_param {
                select ap.parameter_name, ap.package_key, ap.default_value, ap.parameter_id
                from apm_parameters ap, apm_package_types apt
                where
                ap.package_key = apt.package_key
                and apt.singleton_p ='t'
                and ap.package_key <> 'acs-kernel' and ap.package_key <> 'search'
            }] {

                lassign $tuple parameter_name package_key default_value parameter_id
                set value [random]
                if {$parameter_name ne "PasswordExpirationDays" && $value > 0.7} {

                    set package_id [apm_package_id_from_key $package_key]
                    set actual_value [db_string real_value {
                        select apm_parameter_values.attr_value
                        from   apm_parameter_values
                        where apm_parameter_values.package_id = :package_id
                        and apm_parameter_values.parameter_id = :parameter_id
                    }]

                    aa_log "$package_key $parameter_name $actual_value"
                    aa_equals "check parameter::get" \
                        [parameter::get -package_id $package_id -parameter $parameter_name] \
                        $actual_value
                    aa_equals "check parameter::get_from_package_key" \
                        [parameter::get_from_package_key -package_key $package_key -parameter $parameter_name] \
                        $actual_value

                    parameter::set_default -package_key $package_key -parameter $parameter_name -value $value
                    set value_db [db_string get_values {
                        select default_value from apm_parameters
                        where package_key = :package_key and parameter_name = :parameter_name
                    }]
                    aa_equals "check parameter::set_default" $value $value_db
                    set value [expr {$value + 10}]

                    parameter::set_from_package_key -package_key $package_key -parameter $parameter_name -value $value
                    aa_equals "check parameter::set_from_package_key" \
                        [parameter::get -package_id $package_id -parameter $parameter_name] \
                        $value

                    set value [expr {$value + 10}]
                    parameter::set_value -package_id $package_id -parameter $parameter_name -value $value
                    aa_equals "check parameter::set_value" \
                        [parameter::get -package_id $package_id -parameter $parameter_name] \
                        $value

                    ad_parameter_cache -delete $package_id $parameter_name

                    break
                }
            }
    }
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
    -procs acs_user::registered_user_p \
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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
