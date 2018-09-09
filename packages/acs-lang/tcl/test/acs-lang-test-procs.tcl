ad_library {
    Helper test Tcl procedures.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 18 October 2002
}

namespace eval lang::test {}

ad_proc -private lang::test::get_dir {} {
    The test directory of the acs-lang package (where this file resides).

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 28 October 2002
} {
    return "[acs_package_root_dir acs-lang]/tcl/test"
}

ad_proc -private lang::test::assert_browser_locale {accept_language expect_locale} {
    Assert that with given accept language header lang::conn::browser_locale returns
    the expected locale.

    @author Peter Marklund
} {
    ns_set update [ns_conn headers] "Accept-Language" $accept_language
    set browser_locale [lang::conn::browser_locale]
    aa_equals "accept-language header \"$accept_language\"" $browser_locale $expect_locale
}

ad_proc -private lang::test::test_package_key {} {
    return "acs-lang-test-tmp"
}

ad_proc -private lang::test::setup_test_package {} {
    set package_key [test_package_key]
    set package_name "acs-lang temporary test package"
    set package_dir [file join $::acs::rootdir packages $package_key]
    file mkdir $package_dir

    set info_file_path "${package_dir}/${package_key}.info"
    set info_file_contents "<?xml version=\"1.0\"?>
<package key=\"$package_key\" url=\"http://www.openacs.org/acs-repository/apm/packages/$package_key\" type=\"apm_service\">
    <package-name>$package_name</package-name>
    <pretty-plural>$package_name</pretty-plural>
    <initial-install-p>f</initial-install-p>
    <singleton-p>f</singleton-p>

    <version name=\"1.0\" url=\"http://www.openacs.org/acs-repository/download/apm/$package_key-1.0.apm\">
        <owner url=\"mailto:peter@collaboraid.biz\">Peter Marklund</owner>
        <summary>Temporary acs-lang test package</summary>
        <release-date>2003-11-07</release-date>
        <vendor url=\"http://www.collaboraid.biz\">Collaboraid</vendor>
        <description format=\"text/plain\">Temporary test package created by acs-lang test case.</description>
    </version>
</package>
"
    template::util::write_file $info_file_path $info_file_contents

    # Install the test package without catalog files
    apm_package_install \
        -enable \
        [apm_package_info_file_path $package_key]
    aa_true "Package install: package enabled" \
        {$package_key in [apm_enabled_packages]}
}

ad_proc -private lang::test::teardown_test_package {} {
    apm_package_delete -remove_files=1 [test_package_key]
}

ad_proc -private lang::test::check_import_result {
    {-package_key:required}
    {-locale:required}
    {-upgrade_array:required}
    {-base_array:required}
    {-db_array:required}
    {-file_array:required}
} {
    This proc checks that the properties of messages in the database
    are what we expect after a message catalog import or upgrade.

    @author Peter Marklund
} {
    upvar $upgrade_array upgrade_expect
    upvar $base_array base_messages
    upvar $db_array db_messages
    upvar $file_array file_messages

    # Check that we have the expected message properties in the database after upgrade
    foreach message_key [lsort [array names upgrade_expect]] {
        array set expect_property $upgrade_expect($message_key)
        switch $expect_property(message) {
            db {
                set expect_message $db_messages($message_key)
            }
            file {
                set expect_message $file_messages($message_key)
            }
            base {
                set expect_message $base_messages($message_key)
            }
        }

        array unset message_actual
        lang::message::get \
            -package_key $package_key \
            -message_key $message_key \
            -locale $locale \
            -array message_actual

        # Check message properties
        aa_equals "Import check: $message_key - lang_messages.message" \
            $message_actual(message) \
            $expect_message
        aa_equals "Import check: $message_key - lang_messages.deleted_p" \
            $message_actual(deleted_p) \
            $expect_property(deleted_p)
        aa_equals "Import check: $message_key - lang_messages.conflict_p" \
            $message_actual(conflict_p) \
            $expect_property(conflict_p)
        aa_equals "Import check: $message_key - lang_messages.upgrade_status" \
            $message_actual(upgrade_status) \
            $expect_property(upgrade_status)

        if {$expect_property(sync_time) eq "not_null"} {
            aa_true "Import check: $message_key - lang_messages.sync_time not null" \
                {$message_actual(sync_time) ne ""}
        } else {
            aa_true "Import check: $message_key - lang_messages.sync_time null" \
                {$message_actual(sync_time) eq ""}
        }
    }
}

ad_proc -private lang::test::execute_upgrade {
    {-locale:required}
} {
    Executes the logic of the upgrade test case for a certain locale.

    @author Peter Marklund
} {
    set package_key [lang::test::test_package_key]

    # The key numbers correspond to the 14 cases described in the API-doc for lang::catalog::upgrade
    array set base_messages {
        key01 "Key 1"
        key04 "Key 4"
        key05 "Key 5"
        key06 "Key 6"
        key07 "Key 7"
        key10 "Key 10"
        key11 "Key 11"
        key12 "Key 12"
        key13 "Key 13 differ"
        key14 "Key 14 base"
    }

    array set db_messages {
        key02 "Key 2"
        key06 "Key 6 differ"
        key07 "Key 7"
        key08 "Key 8"
        key09 "Key 9"
        key10 "Key 10"
        key11 "Key 11 differ"
        key12 "Key 12"
        key13 "Key 13"
        key14 "Key 14 db"
    }

    array set file_messages {
        key03 "Key 3"
        key04 "Key 4 differ"
        key05 "Key 5"
        key08 "Key 8 differ"
        key09 "Key 9"
        key10 "Key 10"
        key11 "Key 11"
        key12 "Key 12 differ"
        key13 "Key 13"
        key14 "Key 14 file"
    }

    # Add the locale to each message so we can tell messages in
    # different locales apart
    foreach array_name {base_messages db_messages file_messages} {
        foreach message_key [array names $array_name] {
            append ${array_name}($message_key) " $locale"
        }
    }

    array set upgrade_expect {
        key01 {
          message base
          deleted_p t
          conflict_p f
          sync_time not_null
          upgrade_status no_upgrade
        }
        key02 {
          message db
          deleted_p f
          conflict_p f
          sync_time null
          upgrade_status no_upgrade
        }
        key03 {
          message file
          deleted_p f
          conflict_p f
          sync_time not_null
          upgrade_status added
        }
        key04 {
          message file
          deleted_p f
          conflict_p t
          sync_time not_null
          upgrade_status added
        }
        key05 {
          message base
          deleted_p t
          conflict_p f
          sync_time null
          upgrade_status no_upgrade
        }
        key06 {
          message db
          deleted_p t
          conflict_p t
          sync_time not_null
          upgrade_status deleted
        }
        key07 {
          message db
          deleted_p t
          conflict_p f
          sync_time not_null
          upgrade_status deleted
        }
        key08 {
          message file
          deleted_p f
          conflict_p t
          sync_time not_null
          upgrade_status updated
        }
        key09 {
          message db
          deleted_p f
          conflict_p f
          sync_time not_null
          upgrade_status no_upgrade
        }
        key10 {
          message db
          deleted_p f
          conflict_p f
          sync_time not_null
          upgrade_status added
        }
        key11 {
          message db
          deleted_p f
          conflict_p f
          sync_time null
          upgrade_status no_upgrade
        }
        key12 {
          message file
          deleted_p f
          conflict_p f
          sync_time not_null
          upgrade_status updated
        }
        key13 {
          message db
          deleted_p f
          conflict_p f
          sync_time not_null
          upgrade_status no_upgrade
        }
        key14 {
          message file
          deleted_p f
          conflict_p t
          sync_time not_null
          upgrade_status updated
        }
    }

    #
    # Execution plan:
    #
    # 1. Import some messages (base_messages below)
    # 2. Make changes to DB (db_messages below)
    # 3. Make changes to catalog files and import again (file_messages below)
    # 4. Check that merged result is what we expect (upgrade_expect below)
    # 5. Import again
    # 6. Check that we still have the same result (verify idempotent)
    # 7. Resolve some conflicts, but not all
    # 8. Import again
    # 9. Check that we have what's expected then
    #

    aa_log "-------------------------------------------------------------------"
    aa_log "*** Executing upgrade test with locale $locale"
    aa_log "-------------------------------------------------------------------"

    #----------------------------------------------------------------------
    # 1. Import some messages (base_messages)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------1. import some messages----------"

    # Write original catalog file
    set catalog_file_path [lang::catalog::get_catalog_file_path \
                                   -package_key $package_key \
                                   -locale $locale]
    lang::catalog::export_to_file $catalog_file_path [array get base_messages]
    aa_true "Initial export: messages exported to file $catalog_file_path" [file exists $catalog_file_path]

    aa_log [template::util::read_file $catalog_file_path]

    # Import the catalog file
    array unset message_count
    array set message_count [lang::catalog::import -package_key $package_key -locales [list $locale]]
    aa_log "Imported messages: [array get message_count]"

    # Check that we have the expected messages in the database
    array unset actual_db_messages
    array set actual_db_messages [lang::catalog::messages_in_db -package_key $package_key -locale $locale]
    foreach message_key [lsort [array names base_messages]] {
        aa_equals "Initial import: message for key $message_key in db same as in file" \
            $actual_db_messages($message_key) $base_messages($message_key)
    }

    #----------------------------------------------------------------------
    # 2. Make changes to DB (db_messages)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------2. Make changes to DB----------"

    # Carry out changes to the message catalog in the db
    foreach message_key [lsort [array names upgrade_expect]] {

        set register_p 0
        if { ![info exists db_messages($message_key)] } {
            # Message is not supposed to exist in DB
            if { [info exists base_messages($message_key)] } {
                # Message currently does exist in DB: Delete
                aa_log "Deleting message $message_key"
                lang::message::delete \
                    -package_key $package_key \
                    -message_key $message_key \
                    -locale $locale
            }
        } else {
            # Message is supposed to exist in DB
            # Is it new or changed?
            if { ![info exists base_messages($message_key)]
                 || $base_messages($message_key) ne $db_messages($message_key)
             } {
                # Added || updated
                aa_log "Adding/updating message $message_key"
                lang::message::register \
                    $locale \
                    $package_key \
                    $message_key \
                    $db_messages($message_key)
            }
        }
    }

    #----------------------------------------------------------------------
    # 3. Make changes to catalog files and import again (file_messages)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------3. Make changes to catalog files and do first upgrade----------"

    # Update the catalog file
    file delete -force -- $catalog_file_path
    lang::catalog::export_to_file $catalog_file_path [array get file_messages]
    aa_true "First upgrade: catalog file $catalog_file_path updated" [file exists $catalog_file_path]

    # Execute a first upgrade
    lang::catalog::import -package_key $package_key -locales [list $locale]

    #----------------------------------------------------------------------
    # 4. Check that merged result is what we expect (upgrade_expect)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------4. Check merge result of first upgrade----------"
    lang::test::check_import_result \
        -package_key $package_key \
        -locale $locale \
        -upgrade_array upgrade_expect \
        -base_array base_messages \
        -db_array db_messages \
        -file_array file_messages

    #----------------------------------------------------------------------
    # 5. First upgrade (second import)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------5. Second upgrade ----------"
    lang::catalog::import -package_key $package_key -locales [list $locale]

    #----------------------------------------------------------------------
    # 6. Check that we still have the same result (verify idempotent)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------6. Check merge results of second upgrade (verify idempotent)----------"
    lang::test::check_import_result \
        -package_key $package_key \
        -locale $locale \
        -upgrade_array upgrade_expect \
        -base_array base_messages \
        -db_array db_messages \
        -file_array file_messages

    #----------------------------------------------------------------------
    # 7. Resolve some conflicts, but not all
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------7. Resolve some conflicts, but not all----------"
    array set conflict_resolutions {
        key06 "key06 resolution message"
        key08 "accept"
    }
    foreach message_key [array names conflict_resolutions] {
        if {$conflict_resolutions($message_key) eq "accept"} {
            # Resolution is an accept - just toggle conflict_p flag
            lang::message::edit $package_key $message_key $locale [list conflict_p f]

            # Set the message to be what's in the database (the accepted message)
            set conflict_resolutions($message_key) [lang::message::get_element \
                                                        -package_key $package_key \
                                                        -message_key $message_key \
                                                        -locale $locale \
                                                        -element message]
        } else {
            # Resolution is an edit
            lang::message::register \
                $locale \
                $package_key \
                $message_key \
                $conflict_resolutions($message_key)
        }
    }

    # TODO: test resolution being to retain the message (just toggle conflict_p)
    # TODO: test resolution being to delete a resurrected message
    # TODO: test other resolution possibilities

    #----------------------------------------------------------------------
    # 8. Third upgrade
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------8. Do third upgrade----------"
    lang::catalog::import -package_key $package_key -locales [list $locale]

    #----------------------------------------------------------------------
    # 9. Check that we have what's expected then (resolutions are sticky)
    #----------------------------------------------------------------------
    aa_log "locale=$locale ----------9. Check results of third upgrade (that resolutions are sticky)----------"
    foreach message_key [array names conflict_resolutions] {

        array unset message_array
        lang::message::get \
            -package_key $package_key \
            -message_key $message_key \
            -locale $locale \
            -array message_array

        aa_equals "$message_key - conflict message that has been resolved in UI has conflict_p=f" \
            $message_array(conflict_p) "f"
        aa_equals "$message_key - the resolved conflict is not clobbered by an additional import" \
            $message_array(message) $conflict_resolutions($message_key)
    }
}

aa_register_case \
    -procs {
        lang::catalog::export_to_file
        lang::catalog::package_catalog_dir
        lang::catalog::parse
        lang::catalog::read_file
        lang::message::unregister
        lang::test::get_dir
        lang::util::get_temporary_tags_indices
        lang::util::replace_temporary_tags_with_lookups
    } util__replace_temporary_tags_with_lookups {

    A test Tcl file and catalog file are created. The temporary tags in the
    Tcl file are replaced with message lookups and keys and messages are appended
    to the catalog file.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 18 October 2002
} {
    # Peter NOTE: cannot get this test case to work with the rollback code in automated testing
    # and couldn't track down why. I'm threrefor resorting to manual teardown which is fragile and hairy

    # The files involved in the test
    set package_key acs-lang
    set test_dir [lang::test::get_dir]
    set catalog_dir [lang::catalog::package_catalog_dir $package_key]
    set catalog_file "${catalog_dir}/acs-lang.xxx_xx.ISO-8859-1.xml"
    set backup_file_suffix ".orig"
    set catalog_backup_file "${catalog_file}${backup_file_suffix}"
    regexp {^.*(packages/.*)$} $test_dir match test_dir_rel
    set tcl_file "${test_dir_rel}/test-message-tags.tcl"
    set tcl_backup_file "${tcl_file}${backup_file_suffix}"

    # The test messages to use for the catalog file
    array set messages_array [list key_1 text_1 key_2 text_2 key_3 text_3]
    # NOTE: must be kept up-to-date for teardown to work
    set expected_new_keys [list Auto_Key key_1_1]

    # Write the test Tcl file
    set tcl_file_id [open "$::acs::rootdir/$tcl_file" w]
    set new_key_1 "_"
    set new_text_1 "Auto Key"
    set new_key_2 "key_1"
    set new_text_2 "text_1_different"
    set new_key_3 "key_1"
    set new_text_3 "$messages_array(key_1)"
    puts $tcl_file_id "# The following key should be auto-generated and inserted
    # <#  ${new_key_1} ${new_text_1} #>
    #
    # The following key should be made unique and inserted
    # <#${new_key_2} ${new_text_2}#>
    #
    # The following key should not be inserted in the message catalog
    # <#${new_key_3} ${new_text_3}#>"
    close $tcl_file_id

    # Write the catalog file
    lang::catalog::export_to_file $catalog_file [array get messages_array]

    # We need to force the API to export to the test catalog file
    aa_stub lang::catalog::get_catalog_file_path "
        return $catalog_file
    "

    # Replace message tags in the Tcl file and insert into catalog file
    lang::util::replace_temporary_tags_with_lookups $tcl_file

    aa_unstub lang::catalog::get_catalog_file_path

    # Read the contents of the catalog file
    array set catalog_array [lang::catalog::parse [lang::catalog::read_file $catalog_file]]
    array set updated_messages_array $catalog_array(messages)

    # Assert that the old messages are unchanged
    foreach old_message_key [array names messages_array] {
        aa_equals "old key $old_message_key should be unchanged" \
            $messages_array($old_message_key) \
            $updated_messages_array($old_message_key)
    }

    # Check that the first new key was autogenerated
    aa_equals "check autogenerated key" $updated_messages_array(Auto_Key) $new_text_1

    # Check that the second new key was made unique and inserted
    aa_equals "check key made unique" $updated_messages_array(${new_key_2}_1) $new_text_2

    # Check that the third key was not inserted
    aa_equals "third key not inserted"  \
        [lindex [array get updated_messages_array $new_key_3] 1] \
        $messages_array($new_key_3)

    # Check that there are no tags left in the Tcl file
    set tcl_file_id [open "$::acs::rootdir/$tcl_file" r]
    set updated_tcl_contents [read $tcl_file_id]
    close $tcl_file_id
    aa_equals "tags in Tcl file replaced" \
        [llength [lang::util::get_temporary_tags_indices $updated_tcl_contents]] \
        0

    # Delete the test message keys
    foreach message_key [concat [array names messages_array] $expected_new_keys] {
        lang::message::unregister $package_key $message_key
    }
    # Delete the catalog files
    file delete -- $catalog_backup_file
    file delete -- $catalog_file

    # Delete the Tcl files
    file delete -- $::acs::rootdir/$tcl_file
    file delete -- $::acs::rootdir/$tcl_backup_file
}

aa_register_case \
    -procs {
        lang::util::get_hash_indices
    } util__get_hash_indices {

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 21 October 2002
} {
  set multilingual_string "#package1.key1# abc\# #package2.key2#"
  set indices_list [lang::util::get_hash_indices $multilingual_string]
  set expected_indices_list [list [list 0 14] [list 21 35]]

  aa_true "there should be two hash entries" {[llength $indices_list] == 2}

  set counter 0
  foreach index_item $indices_list {
      set expected_index_item [lindex $expected_indices_list $counter]

      aa_true "checking start and end indices of item $counter" {
          [lindex $index_item 0] eq [lindex $expected_index_item 0]
          && [lindex $index_item 1] eq [lindex $expected_index_item 1]
      }
      incr counter
  }
}

aa_register_case \
    -procs {
        lang::util::convert_adp_variables_to_percentage_signs
        lang::util::convert_percentage_signs_to_adp_variables
    } util__convert_adp_variables_to_percentage_signs {

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 25 October 2002
} {
    set adp_chunk "<property name=\"title\">@array.variable_name@ @variable_name2;noquote@ peter@collaboraid.biz</property>"
    set adp_chunk_converted [lang::util::convert_adp_variables_to_percentage_signs $adp_chunk]
    set adp_chunk_expected "<property name=\"title\">%array.variable_name% %variable_name2;noquote% peter@collaboraid.biz</property>"
    aa_equals "adp vars should be substituted with percentage sings" $adp_chunk_converted $adp_chunk_expected
    set adp_chunk_converted_back [lang::util::convert_percentage_signs_to_adp_variables $adp_chunk_converted]
    aa_equals "after having converted the text with percentage signs back to adp we should have what we started with" $adp_chunk_converted $adp_chunk_expected

    # Test that a string can start with adp vars
    set adp_chunk "@first_names.foobar;noquote@ @last_name@&nbsp;peter@collaboraid.biz"
    set adp_chunk_converted [lang::util::convert_adp_variables_to_percentage_signs $adp_chunk]
    set adp_chunk_expected "%first_names.foobar;noquote% %last_name%&nbsp;peter@collaboraid.biz"
    aa_equals "adp vars should be substituted with percentage sings" $adp_chunk_converted $adp_chunk_expected
    set adp_chunk_converted_back [lang::util::convert_percentage_signs_to_adp_variables $adp_chunk_converted]
    aa_equals "after having converted the text with percentage signs back to adp we should have what we started with" $adp_chunk_converted $adp_chunk_expected

    set percentage_chunk {You are <a href="%role.character_url%">%role.character_title%</a> (%role.role_pretty%)}
    set percentage_chunk_converted [lang::util::convert_percentage_signs_to_adp_variables $percentage_chunk]
    set percentage_chunk_expected {You are <a href="@role.character_url@">@role.character_title@</a> (@role.role_pretty@)}
    aa_equals "converting percentage vars to adp vars" $percentage_chunk_converted $percentage_chunk_expected
}

aa_register_case \
    -procs {
        lang::test::get_dir
        lang::util::replace_adp_text_with_message_tags
    } util__replace_adp_text_with_message_tags {

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 28 October 2002
} {
    # File paths used
    set adp_file_path "[lang::test::get_dir]/adp_tmp_file.adp"

    # Write the adp test file
    set adp_file_id [open $adp_file_path w]
    puts $adp_file_id "<master src=\"master\">
<property name=\"title\">@first_names@ @last_name@&nbsp;peter@collaboraid.biz</property>
<property name=\"context_bar\">@context_bar@</property>
Test text"
    close $adp_file_id

    # Do the substitutions
    lang::util::replace_adp_text_with_message_tags $adp_file_path "write"

    # Read the changed test file
    set adp_file_id [open $adp_file_path r]
    set adp_contents [read $adp_file_id]
    close $adp_file_id

    set expected_adp_pattern {<master src=\"master\">
<property name=\"title\"><#[a-zA-Z_]+ @first_names@ @last_name@&nbsp;peter@collaboraid.biz#></property>
<property name=\"context_bar\">@context_bar@</property>
<#[a-zA-Z_]+ Test text\s*}

    # Assert proper replacements have been done
    aa_true "replacing adp text with tags" \
            [regexp $expected_adp_pattern $adp_contents match]

    # Remove the adp test file
    file delete -- $adp_file_path
}

aa_register_case \
        -procs {
            lang::message::format
        } message__format {

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 21 October 2002
} {

    set localized_message "The %frog% jumped across the %fence%. About 50% of the time, he stumbled, or maybe it was %%20 %times%."
    set value_list {frog frog fence fence}

    set subst_message [lang::message::format $localized_message $value_list]
    set expected_message "The frog jumped across the fence. About 50% of the time, he stumbled, or maybe it was %20 %times%."

    aa_equals "the frog should jump across the fence" $subst_message $expected_message

    set my_var(my_key) foo
    set localized_message "A text with an array variable %my_var.my_key% in it"
    set subst_message [lang::message::format $localized_message {} 1]
    set expected_message "A text with an array variable foo in it"
    aa_equals "embedded array variable" $subst_message $expected_message
}

aa_register_case \
        -procs {
            lang::message::get_embedded_vars
            util_get_subset_missing
            util_sets_equal_p
        } message__get_embedded_vars {

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 12 November 2002
} {
    set en_us_message "This message contains no vars"
    set new_message "This is a message with some %vars% and some more %variables%"

    set missing_vars_list [util_get_subset_missing \
            [lang::message::get_embedded_vars $new_message] \
            [lang::message::get_embedded_vars $en_us_message]]

    if { ![aa_true "Find missing vars 'vars' and 'variables'" [util_sets_equal_p $missing_vars_list { vars variables }]] } {
        aa_log "Missing variables returned was: '$missing_vars_list'"
        aa_log "en_US Message: '$en_us_message' -> Variables: '[lang::message::get_embedded_vars $en_us_message]'"
        aa_log "Other Message: '$new_message' -> Variables: '[lang::message::get_embedded_vars $new_message]'"
    }

    # This failed on the test servers
    set en_us_message "Back to %ad_url%%return_url%"
    set new_message "Tillbaka till %ad_url%%return_url%"
    set missing_vars_list [util_get_subset_missing \
            [lang::message::get_embedded_vars $new_message] \
            [lang::message::get_embedded_vars $en_us_message]]
    if { ![aa_equals "No missing vars" [llength $missing_vars_list] 0] } {
        aa_log "Missing vars: $missing_vars_list"
    }

    # Testing variables with digits in the variable names
    set en_us_message "Some variables %var1%%var2% again"
    set new_message "Nogle variable %var1%%var2% igen"
    set missing_vars_list [util_get_subset_missing \
            [lang::message::get_embedded_vars $new_message] \
            [lang::message::get_embedded_vars $en_us_message]]
    if { ![aa_equals "No missing vars" [llength $missing_vars_list] 0] } {
        aa_log "Missing vars: $missing_vars_list"
    }
}

aa_register_case \
        -procs {
            apm_package_id_from_key
            lang::system::locale
            lang::system::locale
            lang::system::set_locale
            lang::system::site_wide_locale
            parameter::set_value
        } locale__test_system_package_setting {
    Tests whether the system package level setting works

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-08-12
} {
    set use_package_level_locales_p_org [parameter::get \
                                             -parameter UsePackageLevelLocalesP \
                                             -package_id [apm_package_id_from_key "acs-lang"]]

    parameter::set_value \
        -parameter UsePackageLevelLocalesP \
        -package_id [apm_package_id_from_key "acs-lang"] -value 1


    # There's no foreign key constraint on the locales column, so this
    # should work
    set locale_to_set [ad_generate_random_string]

    set retrieved_locale {}

    ad_try {
        # Let's pick a random unmounted package to test with
        set package_id [apm_package_id_from_key "acs-kernel"]

        set org_setting [lang::system::site_wide_locale]

        lang::system::set_locale -package_id $package_id $locale_to_set

        set retrieved_locale [lang::system::locale -package_id $package_id]

    } on error {errorMsg} {
        # rethrow error
        error $errorMsg $::errorInfo
    } finally {
        parameter::set_value \
            -parameter UsePackageLevelLocalesP \
            -package_id [apm_package_id_from_key "acs-lang"] \
            -value $use_package_level_locales_p_org
    }

    aa_equals "Retrieved system locale ('$retrieved_locale') equals the one we just set ('$locale_to_set')" \
        $locale_to_set \
        $retrieved_locale
}

aa_register_case \
        -procs {
            lang::conn::browser_locale
            lang::system::locale_set_enabled
        } locale__test_lang_conn_browser_locale {

    @author Peter Marklund
    @creation-date 2003-08-13
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

        # The tests assume that the danish locale is enabled
        lang::system::locale_set_enabled -locale "da_DK" -enabled t

        # First locale is perfect language match
        lang::test::assert_browser_locale "da,en-us;q=0.8,de;q=0.5,es;q=0.3" "da_DK"

        # First locale is perfect locale match
        lang::test::assert_browser_locale "da_DK,en-us;q=0.8,de;q=0.5,es;q=0.3" "da_DK"

        # Tentative match being discarded
        lang::test::assert_browser_locale "da_BLA,foobar,en" "en_US"

        # Tentative match being used
        lang::test::assert_browser_locale "da_BLA,foobar" "da_DK"

        # Several tentative matches, all being discarded
        lang::test::assert_browser_locale "da_BLA,foobar,da_BLUB,da_DK" "da_DK"
    }
}


aa_register_case \
        -cats db \
        strange_oracle_problem {
    Strange Oracle problem when selecting by language

} {
    set language "da "
    set locale da_DK

    set db_string [db_string select_default_locale {
        select locale
        from   ad_locales
        where  language = :language
    } -default "WRONG"]

    aa_false "Does not return 'WRONG'" [string equal $db_string "WRONG"]
}


aa_register_case \
        -procs {
            lang::conn::timezone
            lang::system::set_timezone
            lang::system::timezone
            lang::system::timezone_support_p
            lang::user::set_timezone
            lang::user::timezone
            lc_list_all_timezones
        } set_get_timezone {

    Test that setting and getting user timezone works
} {
    # We cannot test timezones if they are not installed
    if { [lang::system::timezone_support_p] } {

        # Make sure we have a logged in user
        set org_user_id [ad_conn user_id]

        if { $org_user_id == 0 } {
            set user_id [db_string user { select min(user_id) from users }]
            ad_conn -set user_id $user_id
        } else {
            set user_id $org_user_id
        }

        # Remember originals so we can restore them
        set system_timezone [lang::system::timezone]
        set user_timezone [lang::user::timezone]

        set timezones [lc_list_all_timezones]
        set n [expr {[llength $timezones]-1}]

        set desired_user_timezone [lindex $timezones [randomRange $n] 0]
        set desired_system_timezone [lindex $timezones [randomRange $n] 0]

        set error_p 0
        ad_try {
            # User timezone
            lang::user::set_timezone $desired_user_timezone
            aa_equals "User timezone retrieved is the same as the one set" \
                [lang::user::timezone] \
                $desired_user_timezone

            # Storage
            set user_id [ad_conn user_id]
            aa_equals "User timezone stored in user_preferences table" \
                [db_string user_prefs { select timezone from user_preferences where user_id = :user_id }] \
                $desired_user_timezone


            # System timezone
            lang::system::set_timezone $desired_system_timezone
            aa_equals "System timezone retrieved is the same as the one set" \
                [lang::system::timezone] \
                $desired_system_timezone

            # Connection timezone
            aa_equals "Using user timezone" \
                [lang::conn::timezone] \
                $desired_user_timezone

            ad_conn -set isconnected 0
            aa_equals "Fallback to system timezone when no connection" \
                [lang::conn::timezone] \
                $desired_system_timezone
            ad_conn -set isconnected 1

            lang::user::set_timezone {}
            aa_equals "Fallback to system timezone when no user pref" \
                [lang::conn::timezone] \
                $desired_system_timezone

        } on error {errorMsg} {
            set error_p 1
            # rethrow the error
            error $errorMsg $::errorInfo

        } finally {
            lang::system::set_timezone $system_timezone
            lang::user::set_timezone $user_timezone
            ad_conn -set user_id $org_user_id
        }
    }
}

aa_register_case \
        -procs {
            lang::conn::timezone
            lang::system::timezone
            lang::system::timezone_support_p
            lang::user::set_timezone
        } set_timezone_not_logged_in {
    Test that setting and getting user timezone throws an error when user is not logged in
} {
    # We cannot test timezones if they are not installed
    if { [lang::system::timezone_support_p] } {

        set user_id [ad_conn user_id]

        ad_conn -set user_id 0
        aa_equals "Fallback to system timezone when no user" \
            [lang::conn::timezone] \
            [lang::system::timezone]

        set error_p [catch { lang::user::set_timezone [lang::system::timezone] } errmsg]
        aa_true "Error when setting user timezone when user not logged in" $error_p

        # Reset the user_id
        ad_conn -set user_id $user_id
    }
}

aa_register_case \
    -procs {
        lang::conn::timezone
        lc_time_fmt
    } lc_time_fmt_Z_timezone {
    lc_time_fmt %Z returns current connection timezone
} {
    aa_equals "%Z returns current timezone" \
        [lc_time_fmt "2003-08-15 13:40:00" "%Z"] \
        [lang::conn::timezone]
}

aa_register_case \
    -procs {
        lang::message::lookup
        lang::message::register
    } locale_language_fallback {
    Test that we fall back to 'default locale for language' when requesting a message
    which exists in default locale for language, but not in the current locale
} {
    # Assuming we have en_US and en_GB

    set package_key "acs-lang"
    set message_key [ad_generate_random_string]

    set us_message [ad_generate_random_string]
    set gb_message [ad_generate_random_string]

    set error_p 0
    ad_try {
        lang::message::register "en_US" $package_key $message_key $us_message

        aa_equals "Looking up message in GB returns US message" \
            [lang::message::lookup "en_GB" "$package_key.$message_key" "NOT FOUND"] \
            $us_message

        lang::message::register "en_GB" $package_key $message_key $gb_message

        aa_equals "Looking up message in GB returns GB message" \
            [lang::message::lookup "en_GB" "$package_key.$message_key" "NOT FOUND"] \
            $gb_message
    } on error {errorMsg} {
        set error_p 1
        set saved_errorInfo $::errorInfo
        error $errorMsg $saved_errorInfo

    } finally {
        # Clean up
        db_dml delete_msg { delete from lang_messages where package_key = :package_key and message_key = :message_key }
        db_dml delete_key { delete from lang_message_keys where package_key = :package_key and message_key = :message_key }
    }
}

aa_register_case \
    -procs {
        lang::catalog::import
        lang::message::edit
        lang::message::get
        lang::message::unregister
        lang::system::locale_set_enabled
        lang::test::execute_upgrade
        lang::test::setup_test_package
        lang::test::teardown_test_package
    } upgrade {
    Test that a package can be upgraded with new
    catalog files and that the resulting keys and messages
    in the database can then be exported properly.

    What we are testing is a scenario similar to what we have on the OpenACS
    Translation server (http://translate.openacs.org).

    @author Peter Marklund
} {
    # Create the test package in the file system
    lang::test::setup_test_package

    # Can't run this test case with the usual rollback switch since if everything
    # is wrapped in one transaction then the creation_date of the messages will be the
    # same and the query in lang::catalog::last_sync_messages will return duplicates.
    aa_run_with_teardown \
        -test_code {

        lang::test::execute_upgrade -locale en_US

        lang::system::locale_set_enabled \
            -locale de_DE \
            -enabled_p t

        lang::test::execute_upgrade -locale de_DE

    } -teardown_code {
        foreach message_key [array names upgrade_expect] {
            lang::message::unregister $package_key $message_key
        }
        lang::test::teardown_test_package
    }
}

aa_register_case -procs {
    lang::message::register
    lang::message::unregister
    lang::util::localize
} localize {

    @author Peter Marklund
} {
    set package_key "acs-lang"
    set message_key "__test-key"
    set message "Test message"

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # Create a temporary test message to test with
            lang::message::register en_US $package_key $message_key $message

            # Create some random character strings to surround the embedded key
            set pre_text "a;<ls#;#kdfj'...,mlkjoiu><wgon"
            set post_text "a;lskd<fj'...,mlkjo>iuwgon#"
            set message_key_embedded "#${package_key}.${message_key}#"

            # Test replacements
            set text1 $message_key_embedded
            aa_equals "One message key with no surrounding text" \
                [lang::util::localize $text1] \
                $message

            set text1 "${pre_text}${message_key_embedded}${post_text}"
            aa_equals "One message key with surrounding text" \
                [lang::util::localize $text1] \
                "${pre_text}${message}${post_text}"

            set text1 "${pre_text}${message_key_embedded}"
            aa_equals "One message key with text before" \
                [lang::util::localize $text1] \
                "${pre_text}${message}"

            set text1 "${message_key_embedded}${post_text}"
            aa_equals "One message key with text after" \
                [lang::util::localize $text1] \
                "${message}${post_text}"

            set text1 "${pre_text}${message_key_embedded}${post_text}${pre_text}${message_key_embedded}${post_text}"
            aa_equals "Two message keys with surrounding text" \
                [lang::util::localize $text1] \
                "${pre_text}${message}${post_text}${pre_text}${message}${post_text}"
        } -teardown_code {
            # We need to clear the cache
            lang::message::unregister $package_key $message_key
        }
}

aa_register_case \
    -procs {
        lang::message::check
    } lang_messages_correct {
    This test calls the checks to ensure a message is correct on every message in the system
} {
    aa_run_with_teardown -rollback -test_code {
        foreach tuple [db_list_of_lists get_message_keys {
            select message_key, package_key, locale, message from lang_messages
        }] {
            lassign $tuple message_key package_key locale message
            aa_false "Message $message_key in package $package_key for locale $locale correct" \
                [catch {lang::message::check $locale $package_key $message_key $message}]
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
