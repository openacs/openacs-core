ad_page_contract {
    Shows APIs for a particular package.

    @param version_id the ID of the version whose API to view.
    @param public_p view only public APIs?
    @param kind view which type of APIs? One of <code>procs_files</code>,
        <code>procs</code> or <code>content</code>.
    @author Jon Salz (jsalz@mit.edu)
    @creation-date 3 Jul 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
    { public_p:boolean "" }
    { kind "procs_files" }
    { about_package_key ""}
} -properties {
    title:onevalue
    context:onevalue
    dimensional_slider:onevalue
    kind:onevalue
    version_id:onevalue
    package_key:onevalue
    procs_files:multirow
    procedures:multirow
    sql_files:multirow
    content_pages:multirow
}

set public_p [::apidoc::set_public $version_id $public_p]

db_0or1row pretty_name_from_package_id {
    select pretty_name, package_key, version_name
      from apm_package_version_info
     where version_id = :version_id
}
if {![info exists pretty_name]} {
    set context ""
    set kind "none"
    set title "No such Package (probably outdated link)"
    set dimensional_slider $title
    return
}

set dimensional_list {
    {
        kind "Kind:" procs_files {
            { procs_files "Library Files" "" }
            { procs       "Procedures"    "" }
            { sql_files   "SQL Files"     "" }
            { content     "Content Pages" "" }
        }
    }
    {
        public_p "Publicity:" 1 {
            { 1 "Public Only" }
            { 0 "All" }
        }
    }
}

set title "$pretty_name $version_name"
set context [list $title]
set dimensional_slider "[ad_dimensional \
        $dimensional_list \
        "" \
        [ad_tcl_vars_to_ns_set version_id kind public_p about_package_key]]"

switch $kind {
    procs_files {
        array set procs [list]

        multirow create procs_files path full_path first_sentence view

        foreach path [apm_get_package_files -package_key $package_key -file_types {tcl_procs include_page}] {
            set full_path "packages/$package_key/$path"
            
            if { [nsv_exists api_library_doc $full_path] } {
                array set doc_elements [nsv_get api_library_doc $full_path]
                set first_sentence [::apidoc::first_sentence [lindex $doc_elements(main) 0]]
                set view procs-file-view
            } else {
                set first_sentence ""
		set view procs-file-view
            }

            multirow append procs_files $path $full_path $first_sentence $view
        }
    }
    procs {
        array set procs [list]

        foreach path [apm_get_package_files -package_key $package_key -file_types tcl_procs] {
            if { [nsv_exists api_proc_doc_scripts "packages/$package_key/$path"] } {
                foreach proc [nsv_get api_proc_doc_scripts "packages/$package_key/$path"] {
                    set procs($proc) 1
                }
            }
        }

        multirow create procedures proc first_sentence

        foreach proc [lsort [array names procs]] {
            array set doc_elements [nsv_get api_proc_doc $proc]
            if { $public_p } {
                if { !$doc_elements(public_p) } {
                    continue
                }
            }
            multirow append procedures $proc [::apidoc::first_sentence [lindex $doc_elements(main) 0]]
        }
    }
    sql_files {
        multirow create sql_files path relative_path

        set file_types [list data_model data_model_create data_model_drop data_model_upgrade]
        foreach path [apm_get_package_files -include_data_model_files -package_key $package_key -file_types $file_types] {
           # Set relative path to everything after sql/ (just using
           # file tail breaks when you've got subdirs of sql)
           regexp {^sql/(.*)} $path match relative_path

           multirow append sql_files $path $relative_path
        }
    }
    content {
        multirow create content_pages indentation full_path content_type name type first_sentence
        set last_components [list]
        foreach path [apm_get_package_files -package_key $package_key -file_types content_page] {
            set components [split $path "/"]
            if { [info exists doc_elements] } {
                unset doc_elements
            }
            # don't stop completely if the page is gone
            if { [catch {
                set full_path "packages/$package_key/$path"
                array set doc_elements [api_read_script_documentation $full_path]

                for { set n_same_components 0 } \
                        { $n_same_components < [llength $last_components] } \
                        { incr n_same_components } {
                    if { [lindex $last_components $n_same_components] ne [lindex $components $n_same_components] } {
                        break
                    }
                }

                for { set i $n_same_components } { $i < [llength $components] } { incr i } {
                    set indentation ""
                    for { set j 0 } { $j < $i } { incr j } {
                        append indentation "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
                    }
                    set name [lindex $components $i]
                    set type ""
                    set first_sentence ""
                    if { $i == [llength $components] - 1 } {
                        set content_type page
                        if { [info exists doc_elements(type)] } {
                            set type $doc_elements(type)
                        }
                        if { [info exists doc_elements(main)] } {
                            set first_sentence [::apidoc::first_sentence [lindex $doc_elements(main) 0]]
                        }
                    } else {
                        set content_type directory
                    }
                    multirow append content_pages $indentation $full_path $content_type $name $type $first_sentence
                }
                set last_components $components
            } error] } {
                ns_log Error "API Broswer: Package View: $error"
                # couldn't read info from the file. it probably doesn't exist.
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
