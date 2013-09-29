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

set user_id [ad_conn user_id]

# Determine the user's email address.  If its not registered, put in a default.  
set my_email [db_string email_by_user_id {
    select email from parties where party_id = :user_id
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
	    {latest "Latest" {where "[db_map latest]" } }
	    {all "All" {where "1 = 1"} }
	}
    }
}
# "latest" means that a version is installed or enabled, or there is no more latest version
# which is installed or enabled. Basically, any relevant package on the system.
set filter_where_clause [ad_dimensional_sql $dimensional_list where and]
set dimensional_list [ad_dimensional $dimensional_list]

set missing_text "No packages match criteria."
set use_watches_p [expr {![parameter::get -package_id [ad_acs_kernel_id] -parameter PerformanceModeP -default 1]}]

template::list::create -name package_list \
    -multirow packages \
    -no_data $missing_text \
    -key package_key \
    -elements {
        package_key {
            label "Key"
            link_url_col package_url
            orderby "package_key"
        }
        pretty_name {
            label "Name"
            link_url_col package_url
            orderby "pretty_name"
        }
        version_name {
            label "Ver."
            orderby "version_name"
        }
        release_date {
            label "Released"
            orderby "release_date"
        }
        status {
            label "Status"
        }
        maintained {
            label "Maintained"
        }
        action {
            label ""
            display_template {@packages.action_html;noquote@}
        }
    } -filters {owned_by {} supertype {} status {}}

set performance_p [parameter::get -package_id [ad_acs_kernel_id] -parameter PerformanceModeP -default 1] 
set reload_links_p [ad_decode [ns_set iget [rp_getform] reload_links_p] \
                        "" 0 [ns_set iget [rp_getform] reload_links_p]]

db_multirow -extend {package_url maintained status action_html} packages apm_table {} {
    set package_url [export_vars -base version-view {version_id}]
    set maintained [ad_decode $distribution_uri "" "Locally" "Externally"]
    
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
    
    set file_link_list [list]
    lappend file_link_list "<a href=\"version-files?version_id=$version_id\">view files</a>"
    if { $installed_p eq "t" && $enabled_p eq "t" } {
        if {!$performance_p} {
            lappend file_link_list "<a href=\"package-watch?package_key=$package_key\">watch all files</a>"
        } 
        if { !$reload_links_p || [apm_version_load_status $version_id] eq "needs_reload"} {
            lappend file_link_list "<a href=\"version-reload?version_id=$version_id\">reload changed</a>"
        } 
    } 
    set action_html [join $file_link_list " | "]
}

# The reload links make the page slow, so make them optional
set page_url "[ad_conn url]?[export_vars -url {orderby owned_by supertype}]"
if { $reload_links_p } {
    set reload_filter "<a href=\"$page_url&reload_links_p=0\">Do not check for changed files</a>"
} else {
    set reload_filter "<a href=\"$page_url&reload_links_p=1\">Check for changed files</a>"
}

# Build the list of files we're watching.
set watches_html ""
if { $use_watches_p } {
    set watch_files [nsv_array names apm_reload_watch]
    if { [llength $watch_files] > 0 } {
        append watches_html "<h3>Watches</h3><ul>
<li><a href=\"file-watch-cancel\">Stop watching all files</a></li><br>"
        foreach file [lsort $watch_files] {
            if {$file ne "."  } {
                append watches_html "<li>$file (<a href=\"file-watch-cancel?watch_file=[ns_urlencode $file]\">stop watching this file</a>)\n"
            }
        }
        append watches_html "</ul>\n"
    }
} else {
    set kernel_id [ad_acs_kernel_id]
    append watches_html "<h3>Watches</h3>
Watching of files is not enabled in performance mode (see the PerformanceModeP parameter on the <a href=\"/shared/parameters?package_id=$kernel_id&return_url=$page_url\">ACS Kernel parameter page</a>)"
}

