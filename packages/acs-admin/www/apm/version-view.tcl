ad_page_contract {
    Views information about a package.
    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

db_1row apm_all_version_info {}

set downloaded_p [ad_decode $version_uri "" 0 1]

# Obtain information about the enabled version of the package (if there is one).
# We use rownum = 1 in case someone mucks up the database and leaves two package versions
# installed and enabled.
db_0or1row apm_enabled_version_info {
    select version_id as installed_version_id, version_name as installed_version_name,
           enabled_p as installed_enabled_p,
           apm_package_version.version_name_greater(version_name, :version_name) as version_name_greater
    from   apm_package_versions
    where  package_key = :package_key
    and    installed_p = 't'
    and rownum = 1
}

db_0or1row apm_data_model_install_version {
    select data_model_installed_version from (
        select version_name as data_model_installed_version
        from   apm_package_versions
        where  package_key = :package_key
        and    data_model_loaded_p = 't'
        order by apm_package_version.sortable_version_name(version_name) desc
    )
    where rownum = 1
}

if { [empty_string_p $vendor] } {
    set vendor $vendor_uri
}
foreach field { summary description release_date vendor } {
    if { [empty_string_p [set $field]] } {
	set $field "-"
    }
}

# Later we'll output any items in "prompts" as entries in a bullet list at the
# top of the page (these are things that the administrator probably needs to
# address ASAP).
set prompts [list]

if { ![info exists installed_version_id] } {
    if { !$downloaded_p } {
	set status "No version of this package is installed: there is no <tt>.info</tt> file in the
<tt>packages/$package_key</tt> directory. If you're building the package now, you probably
want to <a href=\"version-generate-info?version_id=$version_id&write_p=1\">generate one</a>."
    } else {
	set status "No version of this package is installed. You may <a href=\"version-install\?version_id=$version_id\">install this package now</a>."
    }
    lappend prompts $status
} elseif { $installed_version_id == $version_id } {
    set status "This version of the package is installed"
    if { $enabled_p == "t" } {
	append status " and enabled."
	set can_disable_p 1
    } else {
	append status " but disabled."
	set can_enable_p 1
    }
} else {
    set status "[ad_decode $version_name_greater -1 "An older" "A newer"] version of this package,
version $installed_version_name, is installed and [ad_decode $installed_enabled_p "t" "enabled" "disabled"]."
    if { $version_name_greater < 0 } {
	append body " You may <a href=\"version-upgrade?version_id=$version_id\">upgrade to this version now</a>."
    }
}

if { ![info exists data_model_installed_version] } {
    set data_model_status " No version of the data model for this package has been loaded."
} elseif { [string compare $data_model_installed_version $version_name] } {
    set data_model_status " The data model for version $data_model_installed_version of this package has been
loaded."
} else {
    set data_model_status " The data model for this version of this package has been loaded."
}

if { [file isdirectory "[acs_package_root_dir $package_key]/CVS"] } {
    set cvs_status "This package is under local CVS control."
} else {
    set cvs_status "This package is not under CVS control."
}


# Obtain a list of owners, properly hyperlinked.
set owners [list]
db_foreach apm_all_owners {
    select owner_uri, owner_name from apm_package_owners where version_id = :version_id
} {
    if { [empty_string_p $owner_uri] } {
	lappend owners $owner_name
    } else {
	lappend owners "$owner_name (<a href=\"$owner_uri\">$owner_uri</a>)"
    }
}

if { [llength $owners] == 0 } {
    lappend owners "-"
}

if { [llength $prompts] == 0 } {
    set prompt_text ""
} else {
    set prompt_text "<ul><li>[join $prompts "\n<li>"]</ul>"
}

db_release_unused_handles

set page_title "$pretty_name $version_name"
set context [list [list "../developer" "Developer's Administration"] [list "/acs-admin/apm/" "Package Manager"] $page_title]


append body "
$prompt_text

<h3>Package Information</h3>

<blockquote>
<table>
<tr valign=baseline><th align=left>Package Name:</th><td>$pretty_name</td></th></tr>
<tr valign=baseline><th align=left>Version:</th><td>$version_name</td></tr>
<tr valign=baseline><th align=left>OpenACS Core:</th><td>[ad_decode $initial_install_p "t" "Yes" "No"]</td></tr>
<tr valign=baseline><th align=left>Singleton:</th><td>[ad_decode $singleton_p "t" "Yes" "No"]</td></tr>
<tr valign=baseline><th align=left>Auto-mount:</th><td>$auto_mount</td></tr>
<tr valign=baseline><th align=left>Status:</th><td>$status</td></tr>
<tr valign=baseline><th align=left>Data Model:</th><td>$data_model_status</td></th></tr>
"

set supported_databases_list [apm_package_supported_databases $package_key]
if { [empty_string_p $supported_databases_list] } {
    set supported_databases "none specified"
} else {
    set supported_databases [join $supported_databases_list ", "]
}

append body "
<tr valign=baseline><th align=left>Database Support:</th><td>$supported_databases</td></th></tr>
"

append body "
<tr valign=baseline><th align=left>CVS:</th><td>$cvs_status</td></tr>
<tr valign=baseline><th align=left>[ad_decode [llength $owners] 1 "Owner" "Owners"]:</th><td>[join $owners "<br>"]</td></th></tr>
<tr valign=baseline><th align=left>Package Key:</th><td>$package_key</td></th></tr>
<tr valign=baseline><th align=left>Summary:</th><td>$summary</td></tr>
<tr valign=baseline><th align=left>Description:</th><td>$description</td></tr>
<tr valign=baseline><th align=left>Release Date:</th><td>$release_date</td></tr>"

# Dynamic package version attributes
array set all_attributes [apm::package_version::attributes::get_spec]
array set attributes [apm::package_version::attributes::get \
                          -version_id $version_id \
                          -array attributes]
foreach attribute_name [array names attributes] {
    array set attribute $all_attributes($attribute_name)

    append body "<tr valign=baseline><th align=left>$attribute(pretty_name)</th><td>$attributes($attribute_name)</td></tr>"
}

append body "
<tr valign=baseline><th align=left>Vendor:</th><td>[ad_decode $vendor_uri "" $vendor "<a href=\"$vendor_uri\">$vendor</a>"]</td></tr>
<tr valign=baseline><th align=left>Package URL:</th><td><a href=\"$package_uri\">$package_uri</a></td></th></tr>
<tr valign=baseline><th align=left>Version URL:</th><td><a href=\"$version_uri\">$version_uri</a></td></th></tr>
<tr valign=baseline><th align=left>Distribution File:</th><td>"

if { ![empty_string_p $tarball_length] && $tarball_length > 0 } {
    append body "<a href=\"packages/[file tail $version_uri]?version_id=$version_id\">[format "%.1f" [expr { $tarball_length / 1024.0 }]]KB</a> "
    if { [empty_string_p $distribution_uri] } {
	append body "(generated on this system"
	if { ![empty_string_p $distribution_date] } {
	    append body " on $distribution_date"
	}
	append body ")"
    } else {
	append body "(downloaded from $distribution_uri"
	if { ![empty_string_p $distribution_date] } {
	    append body " on $distribution_date"
	}
	append body ")"
    }
} else {
    append body "None available"
    if { $installed_p == "t" } {
	append body " (<a href=\"version-generate-tarball?version_id=$version_id\">generate one now</a> from the filesystem)"
    }
}

append body "
</td></tr>

</table>
"

append body "
</blockquote>

<ul>
<li><a href=\"version-edit?[export_vars { version_id }]\">Edit above information</a> (Also use this to create a new version)
</ul>
<h4>Manage</h4>
<ul>
<li><a href=\"version-files?[export_vars { version_id }]\">Files</a>
<li><a href=\"version-dependencies?[export_vars { version_id }]\">Dependencies and Provides</a>
<li><a href=\"version-parameters?[export_vars { version_id }]\">Parameters</a>
<li><a href=\"version-callbacks?[export_vars { version_id }]\">Tcl Callbacks (install, instantiate, mount)</a>
<li><a href=\"version-i18n-index?[export_vars { version_id }]\">Internationalization</a>
</ul>
<h4>Reload</h4>
<ul>
<li><a href=\"[export_vars -base version-reload { version_id {return_url [ad_return_url]}}]\">Reload this package</a>
<li><a href=\"[export_vars -base package-watch { package_key {return_url [ad_return_url]}}]\">Watch all files in package</a>
</ul>
<h4>XML .info package specification file</h4>
<ul>
<li><a href=\"version-generate-info?[export_vars { version_id }]\">Display an XML package specification file for this version</a>
"

if { ![info exists installed_version_id] || $installed_version_id == $version_id && \
	[empty_string_p $distribution_uri] } {
    # As long as there isn't a different installed version, and this package is being
    # generated locally, allow the user to write a specification file for this version
    # of the package.
    append body "<li><a href=\"version-generate-info?[export_vars { version_id }]&write_p=1\">Write an XML package specification to the <tt>packages/$package_key/$package_key.info</tt> file</a>\n"
}

if { $installed_p == "t" } {
    if { [empty_string_p $distribution_uri] } {
	# The distribution tarball was either (a) never generated, or (b) generated on this
	# system. Allow the user to make a tarball based on files in the filesystem.
	append body "<p><li><a href=\"version-generate-tarball?[export_vars { version_id }]\">Generate a distribution file for this package from the filesystem</a>\n"
    }

    append body "</ul><h4>Disable/Uninstall</h4><ul>"

    if { [info exists can_disable_p] } {
	append body "<p><li><a href=\"version-disable?[export_vars { version_id }]\">Disable this version of the package</a>\n"
    }
    if { [info exists can_enable_p] } {
	append body "<p><li><a href=\"version-enable?[export_vars { version_id }]\">Enable this version of the package</a>\n"
    }
    
    append body "<p>"
    
    if { $installed_p == "t" } {	
	append body "
	<li><a href=\"package-delete?[export_vars { version_id }]\">Uninstall this package from your system.</a> (be very careful!)\n"
	
    }
}

append body "
</ul>
"
