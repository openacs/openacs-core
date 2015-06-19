ad_page_contract {
    Views information about a package.
    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:naturalnum,optional}
    {package_key:optional}
} -validate {
    version_id_or_package_key {
        if {[info exists package_key] && ![info exists version_id]} {
            set version_id [apm_version_id_from_package_key $package_key]
            if {$version_id eq ""} {
                ad_complain "No package with package_key '$package_key' is enabled."
                return
            }
        }
        if {![info exists version_id]} {
            ad_complain "Specify a valid version_id."
        }
    }
}

db_1row apm_all_version_info {
    select version_id, package_key, package_uri, pretty_name, version_name, version_uri,
    summary, description_format, description, singleton_p, initial_install_p,
    implements_subsite_p, inherit_templates_p,
    to_char(release_date, 'Month DD, YYYY') as release_date , vendor, vendor_uri, auto_mount,
    enabled_p, installed_p, tagged_p, imported_p, data_model_loaded_p, 
    to_char(activation_date, 'Month DD, YYYY') as activation_date,
    tarball_length, distribution_uri,
    to_char(deactivation_date, 'Month DD, YYYY') as deactivation_date,
    to_char(distribution_date, 'Month DD, YYYY') as distribution_date
    from apm_package_version_info 
    where version_id = :version_id
}

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

if { $vendor eq "" } {
    set vendor $vendor_uri
}
foreach field { summary description release_date vendor } {
    if { [set $field] eq "" } {
        set $field "-"
    }
}

# Later we'll output any items in "prompts" as entries in a bullet list at the
# top of the page (these are things that the administrator probably needs to
# address ASAP).
set prompts [list]

if { ![info exists installed_version_id] } {
    if { !$downloaded_p } {
        set href [export_vars -base version-generate-info {version_id {write_p 1}}]
        set status [subst {
            No version of this package is installed: there is no <tt>.info</tt> file in the
            <tt>packages/$package_key</tt> directory. If you're building the package now, you probably
            want to <a href="[ns_quotehtml $href]">generate one</a>.
        }]
    } else {
        set href [export_vars -base version-install {version_id}]
        set status [subst {
            No version of this package is installed. You may 
            <a href="[ns_quotehtml $href]">install this package now</a>.
        }]
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
    set status [subst {
        [ad_decode $version_name_greater -1 "An older" "A newer"] version of this package,
        version $installed_version_name, is installed and [ad_decode $installed_enabled_p "t" "enabled" "disabled"].
    }]
    if { $version_name_greater < 0 } {
        set href [export_vars -base version-upgrade {version_id}]
        append body [subst {
            You may <a href="[ns_quotehtml $href]">upgrade to this version now</a>.
        }]
    }
}

if { ![info exists data_model_installed_version] } {
    set data_model_status " No version of the data model for this package has been loaded."
} elseif {$data_model_installed_version ne $version_name  } {
    set data_model_status " The data model for version $data_model_installed_version of this package has been loaded."
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
    if { $owner_uri eq "" } {
        lappend owners $owner_name
    } else {
        lappend owners [subst {$owner_name (<a href="[ns_quotehtml $owner_uri]">$owner_uri</a>)}]
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

set title "$pretty_name $version_name"
set context [list \
                 [list "../developer" "Developer's Administration"] \
                 [list "/acs-admin/apm/" "Package Manager"] \
                 $title]

append body [subst {
    $prompt_text

    <h3>Package Information</h3>

    <blockquote>
    <table>
    <tr valign="baseline"><th align="left">Package Name:</th><td>$pretty_name</td></tr>
    <tr valign="baseline"><th align="left">Version:</th><td>$version_name</td></tr>
    <tr valign="baseline"><th align="left">OpenACS Core:</th><td>[ad_decode $initial_install_p "t" "Yes" "No"]</td></tr>
    <tr valign="baseline"><th align="left">Singleton:</th><td>[ad_decode $singleton_p "t" "Yes" "No"]</td></tr>
    <tr valign="baseline"><th align="left">Implements Subsite:</th><td>[ad_decode $implements_subsite_p t Yes No]</td></tr>
    <tr valign="baseline"><th align="left">Inherit Templates:</th><td>[ad_decode $inherit_templates_p t Yes No]</td></tr>
    <tr valign="baseline"><th align="left">Auto-mount:</th><td>$auto_mount</td></tr>
    <tr valign="baseline"><th align="left">Status:</th><td>$status</td></tr>
    <tr valign="baseline"><th align="left">Data Model:</th><td>$data_model_status</td></tr>
}]

set supported_databases_list [apm_package_supported_databases $package_key]
if { $supported_databases_list eq "" } {
    set supported_databases "none specified"
} else {
    set supported_databases [join $supported_databases_list ", "]
}

append body [subst {
    <tr valign="baseline"><th align="left">Database Support:</th><td>$supported_databases</td></tr>
    <tr valign="baseline"><th align="left">CVS:</th><td>$cvs_status</td></tr>
    <tr valign="baseline"><th align="left">[ad_decode [llength $owners] 1 "Owner" "Owners"]:</th><td>[join $owners "<br>"]</td></tr>
    <tr valign="baseline"><th align="left">Package Key:</th><td>$package_key</td></tr>
    <tr valign="baseline"><th align="left">Summary:</th><td>$summary</td></tr>
    <tr valign="baseline"><th align="left">Description:</th><td>$description</td></tr>
    <tr valign="baseline"><th align="left">Release Date:</th><td>$release_date</td></tr>
}]

# Dynamic package version attributes
array set all_attributes [apm::package_version::attributes::get_spec]
array set attributes [apm::package_version::attributes::get \
                          -version_id $version_id \
                          -array attributes]
foreach attribute_name [array names attributes] {
    array set attribute $all_attributes($attribute_name)
    append body [subst {
        <tr valign="baseline"><th align="left">$attribute(pretty_name):</th><td>$attributes($attribute_name)</td></tr>
    }]
}

set vendorHTML [ad_decode $vendor_uri "" $vendor [subst {<a href="[ns_quotehtml $vendor_uri]">$vendor</a>}]]
append body [subst {
    <tr valign="baseline"><th align="left">Vendor:</th><td>$vendorHTML</td></tr>
    <tr valign="baseline"><th align="left">Package URL:</th><td><a href="$package_uri">$package_uri</a></td></tr>
    <tr valign="baseline"><th align="left">Version URL:</th><td><a href="$version_uri">$version_uri</a></td></tr>
    <tr valign="baseline"><th align="left">Distribution File:</th><td>
}]

if { $tarball_length ne "" && $tarball_length > 0 } {
    set href [export_vars -base packages/[file tail $version_uri] {version_id}]
    append body [subst {
        <a href="[ns_quotehtml $href]">[format "%.1f" [expr { $tarball_length / 1024.0 }]]KB</a> 
    }]
    if { $distribution_uri eq "" } {
        append body "(generated on this system"
        if { $distribution_date ne "" } {
            append body " on $distribution_date"
        }
        append body ")"
        set href [export_vars -base "http://openacs.org/xowf/package-submissions/PackageSubmit.wf" \
                      {{m create-new} {p.description $summary} {title "[file tail $version_uri]"}}]
        append body [subst {
            <p>
            In order to contribute this package back to the OpenACS community, 
            <ol>
            <li>download the .apm-file to your file system and</li>
            <li>submit the .apm-file 
            <a href="[ns_quotehtml $href]" target="_blank">to 
            the package repository of OpenACS</a>.</li>
            </ol>
        }]
    } else {
        append body "(downloaded from $distribution_uri"
        if { $distribution_date ne "" } {
            append body " on $distribution_date"
        }
        append body ")"
    }
} else {
    append body "None available"
    if { $installed_p == "t" } {
        set href [export_vars -base version-generate-tarball {version_id}]
        append body [subst {
            (<a href="[ns_quotehtml $href]">generate one now</a> from the filesystem)
        }]
    }
}


set nr_instances [apm_num_instances $package_key]
if {$nr_instances > 0} {
    set instances [subst {
        Installed instances of this package:
        <a href="[ns_quotehtml [export_vars -base package-instances { package_key }]]">$nr_instances</a>
    }]
} else {
    set instances "No installed instance of this package\n"
}
if {$nr_instances == 0 || ($nr_instances > 0 && !$singleton_p)} {
    set href [export_vars -base package-instance-create { package_key {return_url [ad_return_url]}}]
    set instance_create [subst {
        <li><a href="[ns_quotehtml $href]">Create 
        (unmounted) instance of this package</a></li>
    }]
} else {
    set instance_create ""
}

append body [subst {
    </td></tr>
    </table>
    </blockquote>

    <ul>
    <li><a href="[ns_quotehtml [export_vars -base version-edit {version_id}]]">Edit
    above information</a> (Also use this to create a new version)</li>
    </ul>
    <h4>Manage</h4>
    <ul>
    <li><a href="[ns_quotehtml [export_vars -base version-files        {version_id}]]">Files</a></li>
    <li><a href="[ns_quotehtml [export_vars -base version-dependencies {version_id}]]">Dependencies and Provides</a></li>
    <li><a href="[ns_quotehtml [export_vars -base version-parameters   {version_id}]]">Parameters</a></li>
    <li><a href="[ns_quotehtml [export_vars -base version-callbacks    {version_id}]]">Tcl Callbacks (install, instantiate, mount)</a></li>
    <li><a href="[ns_quotehtml [export_vars -base version-i18n-index   {version_id}]]">Internationalization</a></li>
    <li>$instances</li>
    $instance_create
    </ul>
    <h4>Reload</h4>
    <ul>
    <li><a href="[ns_quotehtml [export_vars -base version-reload {version_id  {return_url [ad_return_url]}}]]">Reload
    this package</a></li>
    <li><a href="[ns_quotehtml [export_vars -base package-watch  {package_key {return_url [ad_return_url]}}]]">Watch
    all files in package</a></li>
    </ul>
    <h4>XML .info package specification file</h4>
    <ul>
    <li><a href="[ns_quotehtml [export_vars -base version-generate-info {version_id}]]">Display an
    XML package specification file for this version</a></li>
}]

if { ![info exists installed_version_id] || $installed_version_id == $version_id && 
     $distribution_uri eq "" } {
    # As long as there isn't a different installed version, and this package is being
    # generated locally, allow the user to write a specification file for this version
    # of the package.
    append body [subst {
        <li><a href="[ns_quotehtml [export_vars -base version-generate-info {version_id {write_p 1}}]]">Write 
        an XML package specification to the <tt>packages/$package_key/$package_key.info</tt> file</a></li>
    }]
}

if { $installed_p == "t" } {
    if { $distribution_uri eq "" } {
        # The distribution tarball was either (a) never generated, or (b) generated on this
        # system. Allow the user to make a tarball based on files in the filesystem.
        append body [subst {
            <li><a href="[ns_quotehtml [export_vars -base version-generate-tarball {version_id}]]">Generate 
            a distribution file for this package from the filesystem</a></li>
        }]
    }

    append body "</ul><h4>Disable/Uninstall</h4><ul>"

    if { [info exists can_disable_p] } {
        append body [subst {
            <li><a href="[ns_quotehtml [export_vars -base version-disable {version_id}]]">Disable 
            this version of the package</a></li>
        }]
    }
    if { [info exists can_enable_p] } {
        append body [subst {
            <li><a href="[ns_quotehtml [export_vars -base version-enable {version_id}]]">Enable 
            this version of the package</a></li>
        }]
    }
    
    if { $installed_p == "t" } {    
        append body [subst {
            <li><a href="[ns_quotehtml [export_vars -base package-delete {version_id}]]">Uninstall 
            this package from your system</a> (be very careful!)</li>
        }]
    }
}

append body {
    </ul>
}

ad_return_template apm

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
