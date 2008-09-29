ad_page_contract {
    Index page for the package manager.

    @param orderyby The parameter to order everything in the page by.
    @param owned_by Display packages owned by whom.
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
} {
    { orderby "package_key" }
    { owned_by "everyone" }
    { supertype "all" }
    { reload_links_p 0 }
}

set page_title "Package Manager"
set context [list [list "../developer" "Developer's Administration"] $page_title]

set user_id [ad_get_user_id]

# Determine the user's email address.  If its not registered, put in a default.  
set my_email [db_string email_by_user_id {
    select email  from parties where party_id = :user_id
} -default "me"]

set dimensional_list {
    {
        supertype "Package Type:" all {
	    { apm_application "Applications" { where "[db_map apm_application]" } }
	    { apm_service "Services" { where "t.package_type = 'apm_service'"} }
	    { all "All" {} }
	}
    }
    {

	owned_by "Owned by:" everyone {
	    { me "Me" {where "[db_map everyone]"} }
	    { everyone "Everyone" {where "1 = 1"} }
	}
    }
    {
	status "Status:" latest {
	    {
		latest "Latest" {where "[db_map latest]" }
	    }
	    { all "All" {where "1 = 1"} }
	}
    }
}
# "latest" means that a version is installed or enabled, or there is no more latest version
# which is installed or enabled. Basically, any relevant package on the system.

set missing_text "<strong>No packages match criteria.</strong>"

append body "<center><table><tr><td>[ad_dimensional $dimensional_list]</td></tr></table></center>"

set use_watches_p [expr {![parameter::get -package_id [ad_acs_kernel_id] -parameter PerformanceModeP -default 1]}]

set table_def {
    { package_key "Key" "" "<td><a href=\"[export_vars -base version-view { version_id }]\">$package_key</a></td>" }
    { pretty_name "Name" "" "<td><a href=\"[export_vars -base version-view { version_id }]\">$pretty_name</a></td>" }
    { version_name "Ver." "" "" }
    {
	status "Status" "" {<td align=center>&nbsp;&nbsp;[eval {
	    if { $installed_p eq "t" } {
		if { $enabled_p eq "t" } {
		    set status "Enabled"
		} else {
		    set status "Disabled"
		}
	    } elseif { $superseded_p } {
		set status "Superseded"
	    } else {
		set status "Uninstalled"
	    }
	    format $status
	}]&nbsp;&nbsp;</td>}
    }
    { maintained "Maintained" "" {<td align=center>[ad_decode $distribution_uri "" "Locally" "Externally"]</td>} }
    {
	action "" "" {<td>&nbsp;&nbsp;[eval {

            set file_link_list [list]
            lappend file_link_list "<a href=\"version-files?version_id=$version_id\">view files</a>"

	    if { $installed_p eq "t" && $enabled_p eq "t" } {
	        if {![parameter::get -package_id [ad_acs_kernel_id] -parameter PerformanceModeP -default 1]} {
                    lappend file_link_list "<a href=\"package-watch?package_key=$package_key\">watch all files</a>"
                } 

                set reload_links_p [ad_decode [ns_set iget [rp_getform] reload_links_p] \
                                              "" 0 [ns_set iget [rp_getform] reload_links_p]]
                if { !$reload_links_p || [string equal [apm_version_load_status $version_id] "needs_reload"]} {
                    lappend file_link_list "<a href=\"version-reload?version_id=$version_id\">reload changed</a>"
                } 
            } 

            set format_string [join $file_link_list " | "]
            format $format_string
            

	}]&nbsp;&nbsp;</td>}
    }
}

doc_body_flush

set table [ad_table -Torderby $orderby -Tmissing_text $missing_text "apm_table" "" $table_def]

db_release_unused_handles

# The reload links make the page slow, so make them optional
set page_url "[ad_conn url]?[export_vars -url {orderby owned_by supertype}]"
if { $reload_links_p } {
    set reload_filter "<a href=\"$page_url&reload_links_p=0\">Do not check for changed files</a>"
} else {
    set reload_filter "<a href=\"$page_url&reload_links_p=1\">Check for changed files</a>"
}

append body "<h3>Packages</h3>

<table width=\"100%\">
<tr><td align=\"right\">$reload_filter</td</tr>
</table>

$table

<ul>
<li><a href=\"package-add\">Create a new package.</a>
<li><a href=\"write-all-specs\">Write new specification files for all installed, locally generated packages</a>
<li><a href=\"package-load\">Load a new package from a URL or local directory.</a>
<li><a href=\"packages-install\">Install packages.</a>
</ul>
"

# Build the list of files we're watching.
if { $use_watches_p } {
    set watch_files [nsv_array names apm_reload_watch]
    if { [llength $watch_files] > 0 } {
        append body "<h3>Watches</h3><ul>
<li><a href=\"file-watch-cancel\">Stop watching all files</a></li><br>"
        foreach file [lsort $watch_files] {
            if {$file ne "."  } {
                append body "<li>$file (<a href=\"file-watch-cancel?watch_file=[ns_urlencode $file]\">stop watching this file</a>)\n"
            }
        }
        append body "</ul>\n"
    }
} else {
    set kernel_id [ad_acs_kernel_id]
    append body "<h3>Watches</h3>
Watching of files is not enabled in performance mode (see the PerformanceModeP parameter on the <a href=\"/admin/site-map/parameter-set?package_id=$kernel_id&package_key=acs-kernel&section_name=all\">ACS Kernel parameter page</a>)"
}

append body "
<h3>Help</h3>

<blockquote>
A package is <b>enabled</b> if it is scheduled to run at server startup
and is deliverable by the request processor.

<p>If a Tcl library file (<tt>*-procs.tcl</tt>) or query file (<tt>*.xql</tt>) is being
<b>watched</b>, the request processor monitors it, reloading it into running interpreters
whenever it is changed. This is useful during development
(so you don't have to restart the server for your changes to take
effect). To watch a file, click its package key above, click <i>Manage file
information</i> on the next screen, and click <i>watch</i> next to
the file's name on the following screen.
</blockquote>
"
