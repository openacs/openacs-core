ad_library {

    Search Test Procs

}

#
# This test could be used to make sure binaries in use in the code are
# actually available to the system.
#
# aa_register_case -cats {
#     smoke production_safe
# } -procs {
#     util::which
#     apm_tar_cmd
#     apm_gzip_cmd
# } search_exec_dependencies {
#     Test external command dependencies for this package.
# } {
#     foreach cmd [list \
#                      [::util::which unzip] \
#                      [::util::which file] \
#                      [::util::which catdoc] \
#                      [::util::which xls2csv] \
#                      [::util::which catppt] \
#                      [::util::which pdftotext] \
#                     ] {
#         aa_true "'$cmd' is executable" [file executable $cmd]
#     }
# }

aa_register_case \
    -cats {api smoke} \
    -procs {
        search::convert::binary_to_text
    } \
    convert_binary_to_text {

        Test the conversion of various file types to plain text for
        indexing.

        The test files all contain the word "OpenACS". We test if this
        is correctly extracted.

    } {
        #
        # .ppt conversion is currently only best-effort, as the
        # underlying tool catppt seems to be unreliable even for a
        # trivial document as the one we test here.
        #
        # We comment this test until a better solution is found,
        # e.g. one based on LibreOffice, unoconv or other similar
        # tools.
        #
        # ppt application/mspowerpoint
        #
        foreach {extension mime_type} {
            txt text/plain
            html text/html
            doc application/msword
            xls application/msexcel
            pdf application/pdf
            odt application/vnd.oasis.opendocument.text
            ott application/vnd.oasis.opendocument.text-template
            odp application/vnd.oasis.opendocument.presentation
            otp application/vnd.oasis.opendocument.presentation-template
            ods application/vnd.oasis.opendocument.spreadsheet
            ots application/vnd.oasis.opendocument.spreadsheet-template
            docx application/vnd.openxmlformats-officedocument.wordprocessingml.document
            xlsx application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
            pptx application/vnd.openxmlformats-officedocument.presentationml.presentation
        } {
            set filename [acs_root_dir]/packages/search/tcl/test/data/test.$extension
            set text [search::convert::binary_to_text \
                          -filename $filename \
                          -mime_type $mime_type]
            set ok_p [expr {[string first "OpenACS" $text] >= 0}]
            aa_true "Text was extracted correctly for '.$extension'/'$mime_type'" $ok_p
            if {!$ok_p} {
                aa_log "Extracted text: [ns_quotehtml $text]"
            }
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        search::extra_args
        search::extra_args_names
        search::extra_args_page_contract
    } \
    extra_args {

        Test the API dealing with extra args introduced by the
        full-text engine in use.

    } {
        set expected_names [list]
        foreach procname [info procs ::callback::search::extra_arg::impl::*] {
            lappend expected_names [namespace tail $procname]
        }

        aa_equals "Extra arg names are expected" \
            [search::extra_args_names] $expected_names

        foreach arg $expected_names {
            unset -nocomplain $arg
        }
        aa_equals "Extra args returns empty when no var is defined" \
            [search::extra_args] ""

        set expected_values [list]
        set i 0
        foreach arg $expected_names {
            set $arg $i
            lappend expected_values $arg $i
            incr i
        }
        aa_equals "Extra args returns the values defined in the caller scope" \
            [lsort [search::extra_args]] [lsort $expected_values]


        set expected_contract ""
        foreach name $expected_names {
            append expected_contract "\{$name \{\}\}\n"
        }
        aa_equals "Extra args contract returns expected" \
            [search::extra_args_page_contract] $expected_contract
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        search::queue
        search::dequeue
    } \
    queue_dequeue {

        Test basic queuing, dequeuing of document indexing.

    } {
        set object_id [db_string get_object {select max(object_id) from acs_objects}]

        foreach event {INSERT UPDATE DELETE} {
            db_transaction {
                search::queue -object_id $object_id -event $event
                aa_true "Event '$event' was queued for '$object_id'" [db_0or1row check {
                    select event_date from search_observer_queue
                    where object_id = :object_id and event = :event and event_date = current_timestamp
                }]
                search::dequeue -object_id $object_id -event $event -event_date $event_date
                aa_false "Event '$event' at '$event_date' was dequeued for '$object_id'" [db_0or1row check {
                    select event_date from search_observer_queue
                    where object_id = :object_id and event = :event and event_date = :event_date
                }]
            }
        }

        aa_silence_log_entries -severities {error notice} {
            aa_true "Invalid event throws an error" [catch {
                search::queue -object_id $object_id -event BOGUS
            }]
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        search::driver_name
        search::dotlrn::get_community_id
    } \
    misc {
        Test miscellaneous api
    } {
        aa_section search::dotlrn::get_community_id

        #
        # This is the package we will test when no dotlrn is
        # there. Basically, any package will do.
        #
        set package_id [db_string get_applet_package {
            select max(package_id) from apm_packages
        }]

        if {[apm_package_installed_p dotlrn]} {
            #
            # We try testing a package coming from a community_applet
            # and fall back to any package in case we find none.
            #
            set package_id [db_string get_applet_package {
                select coalesce((select max(package_id) from dotlrn_community_applets),
                                :package_id)
                from dual
            }]

            set site_node [site_node::get_node_id_from_object_id -object_id $package_id]
            set dotlrn_package_id [site_node::closest_ancestor_package \
                                       -node_id $site_node \
                                       -package_key dotlrn \
                                       -include_self]
            set expected_community_id [db_string get_community_id {
                select community_id from dotlrn_communities_all
                where package_id = :dotlrn_package_id
            } -default ""]
        } else {
            set expected_community_id ""
        }

        aa_equals "dotlrn community_id is returned as expected for package '$package_id'" \
            [search::dotlrn::get_community_id -package_id $package_id] \
            $expected_community_id


        aa_section search::driver_name

        aa_equals "Driver name is returned as expected" \
            [search::driver_name] \
            [parameter::get \
                 -package_id [apm_package_id_from_key search] \
                 -parameter FtsEngineDriver]
    }
