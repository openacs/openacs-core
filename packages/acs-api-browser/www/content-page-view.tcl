ad_page_contract {
    Displays information about a content page.
    
    @param version_id the id of the package version the file belongs to
    @param path the path and filename of the page to document, relative to $::acs::rootdir
    
    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @creation-date 1 July 2000
    
    @cvs-id $Id$
} {
    version_id:naturalnum,optional
    source_p:boolean,optional,trim,notnull
    {compiled_p:boolean,optional,trim,notnull 0}
    path:trim,notnull
} -properties {
    title:onevalue
    context:onevalue
    script_documentation:onevalue
}

set context [list]
set url_vars [export_vars {path version_id}]
set return_url [export_vars -base [ad_conn url] {path version_id}]
set default_source_p [ad_get_client_property -default 0 acs-api-browser api_doc_source_p]

if { ![info exists source_p] } {
    set source_p $default_source_p
    if {$source_p eq ""} {
        set source_p 0
    }
}
#
# Allow compiled_p only for swas
#
if {$compiled_p && ![acs_user::site_wide_admin_p]} {
    set complied_p 0
}

#
# If there is no version_id, try to get if from the provided path
#
if { ![info exists version_id]
     && [regexp {^/?packages/([^ /]+)/} $path . package_key] } {
    db_0or1row version_id_from_package_key {
        select version_id 
          from apm_enabled_package_versions 
         where package_key = :package_key
    }
}

if { [info exists version_id] } {
    db_0or1row package_info_from_version_id {
        select pretty_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    if {[info exists pretty_name]} {
        lappend context [list "package-view?version_id=$version_id&kind=content" "$pretty_name $version_name"]
    }
}

lappend context [file tail $path]
set path [apidoc::sanitize_path $path]

if {![file readable $::acs::rootdir/$path] || [file isdirectory $::acs::rootdir/$path]} {
    if {[info exists version_id]} {
	set kind content
	set href [export_vars -base [ad_conn package_url]/package-view {version_id {kind procs}}]
	set link [subst {<p>Go back to <a href="[ns_quotehtml $href]">Package Documentation</a>.}]
    } else {
	set link [subst {<p>Go back to <a href="[ns_quotehtml [ad_conn package_url]]">API Browser</a>.}]
    }
    ad_return_warning \
        "No such content page" \
        [subst {
            The file '$path' was not found. Maybe the url contains a typo.
            $link
        }]
    ad_script_abort

} else {

    set mime_type [ns_guesstype $path]
    if {![string match "text/*" $mime_type] && [ad_file extension $path] ni {.xql .wf}} {
        set source_p 0
        set source_link 0
    } else {
        set source_link 1
    }
    if { $source_p } {
        set contents_title "File Contents"
        set file_contents [template::util::read_file $::acs::rootdir/$path]
        set compiled_file_contents ""
        switch [ad_file extension $path] {
            ".tcl" - ".wf" {
                set file_contents [apidoc::tclcode_to_html $file_contents]
            }
            ".adp" {
                if {$compiled_p} {
                    set contents_title "Compiled ADP File"
                    set file_contents [apidoc::tclcode_to_html [template::adp_compile -file $::acs::rootdir/$path]]
                } else {
                    set file_contents [ns_quotehtml $file_contents]
                }
            }
            default {
                set file_contents [ns_quotehtml $file_contents]
            }
        }
    }

    template::util::list_to_multirow xql_links [::apidoc::xql_links_list \
                                                    -include_compiled [acs_user::site_wide_admin_p] \
                                                    $path]
    set title [file tail $path]
    set script_documentation [api_script_documentation $path]

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
