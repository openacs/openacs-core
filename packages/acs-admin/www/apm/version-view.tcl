ad_page_contract {
    Views information about a package.
    
    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    {version_id:naturalnum,optional}
    {package_key:token,optional}
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

db_1row apm_all_version_info {}

set downloaded_p [expr {$version_uri ne ""}]

# Obtain information about the enabled version of the package (if there is one).
# We use rownum = 1 in case someone mucks up the database and leaves two package versions
# installed and enabled.
db_0or1row apm_enabled_version_info {}
set installed_version_name_greater_p [expr {[apm_version_names_compare $installed_version_name $version_name] == 1}]

db_0or1row apm_data_model_install_version {}

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
        [expr {$installed_version_name_greater_p ? "A newer" : "An older"}] version of this package,
        version $installed_version_name, is installed and [expr {$installed_enabled_p ? "enabled" : "disabled"}].
    }]
    if { !$installed_version_name_greater_p } {
        set version_upgrade_href [export_vars -base version-upgrade {version_id}]
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
db_foreach apm_all_owners {} {
    if { $owner_uri eq "" } {
        lappend owners $owner_name
    } else {
        lappend owners [subst {$owner_name (<a href="[ns_quotehtml $owner_uri]">$owner_uri</a>)}]
    }
}

if { [llength $owners] == 0 } {
    lappend owners "-"
}

if { [llength $prompts] > 0 } {
    set prompt_text [subst {<ul><li>[join $prompts "\n<li>"]</ul>}]
}

set title "$pretty_name $version_name"
set context [list \
                 [list "../developer" "Developer's Administration"] \
                 [list "/acs-admin/apm/" "Package Manager"] \
                 $title]

foreach var {initial_install_p singleton_p implements_subsite_p inherit_templates_p} {
    set ${var}_text #acs-admin.[expr {[set $var] ? "Yes" : "No"}]#
}

set supported_databases_list [apm_package_supported_databases $package_key]
if { $supported_databases_list eq "" } {
    set supported_databases "none specified"
} else {
    set supported_databases [join $supported_databases_list ", "]
}

set nr_owners [llength $owners]
set owners_text [join $owners "<br>"]

# Dynamic package version attributes
array set all_attributes [apm::package_version::attributes::get_spec]
array set attributes [apm::package_version::attributes::get \
                          -version_id $version_id \
                          -array attributes]
foreach attribute_name [array names attributes] {
    array set attribute $all_attributes($attribute_name)
    append attribute_text [subst {
        <tr valign="baseline"><th align="left">$attribute(pretty_name):</th><td>$attributes($attribute_name)</td></tr>
    }]
}

set vendorHTML [expr {$vendor_uri eq "" ? $vendor : [subst {<a href="[ns_quotehtml $vendor_uri]">$vendor</a>}]}]

set distributionHTML ""
if { $tarball_length ne "" && $tarball_length > 0 } {
    set href [export_vars -base packages/[file tail $version_uri] {version_id}]
    append distributionHTML [subst {
        <a href="[ns_quotehtml $href]">[format "%.1f" [expr { $tarball_length / 1024.0 }]]KB</a>
    }]
    if { $distribution_uri eq "" } {
        append distributionHTML "(generated on this system"
        if { $distribution_date ne "" } {
            append distributionHTML " on $distribution_date"
        }
        append distributionHTML ")"
        set href [export_vars -base "https://openacs.org/xowf/package-submissions/PackageSubmit.wf" \
                      {{m create-new} {p.description $summary} {title "[file tail $version_uri]"}}]
        append distributionHTML [subst {
            <p>
            In order to contribute this package back to the OpenACS community,
            <ol>
            <li>download the .apm-file to your filesystem and</li>
            <li>submit the .apm-file
            <a href="[ns_quotehtml $href]" target="_blank">to
            the package repository of OpenACS</a>.</li>
            </ol>
        }]
    } else {
        append distributionHTML "(downloaded from $distribution_uri"
        if { $distribution_date ne "" } {
            append distributionHTML " on $distribution_date"
        }
        append distributionHTML ")"
    }
} else {
    append distributionHTML "None available"
    if { $installed_p == "t" } {
        set href [export_vars -base version-generate-tarball {version_id}]
        append distributionHTML [subst {
            (<a href="[ns_quotehtml $href]">generate one now</a> from the filesystem)
        }]
    }
}


set nr_instances [apm_num_instances $package_key]
if {$nr_instances > 0} {
    set instancesHTML [subst {
        Installed instances of this package:
        <a href="[ns_quotehtml [export_vars -base package-instances { package_key }]]">$nr_instances</a>
    }]
} else {
    set instancesHTML "No installed instance of this package\n"
}
if {$nr_instances == 0 || ($nr_instances > 0 && !$singleton_p)} {
    set href [export_vars -base package-instance-create { package_key {return_url [ad_return_url]}}]
    set instance_createHTML [subst {
        <li><a href="[ns_quotehtml $href]">Create
        (unmounted) instance of this package</a></li>
    }]
} else {
    set instance_createHTML ""
}

set edit_package_info_href  [export_vars -base version-edit         {version_id}]
set version_files_href      [export_vars -base version-files        {version_id}]
set version_dependency_href [export_vars -base version-dependencies {version_id}]
set version_parameters_href [export_vars -base version-parameters   {version_id}]
set version_callbacks_href  [export_vars -base version-callbacks    {version_id}]
set i18_href                [export_vars -base version-i18n-index   {version_id}]
set reload_href             [export_vars -base version-reload {version_id {return_url [ad_return_url]}}]
set watch_href              [export_vars -base package-watch  {package_key {return_url [ad_return_url]}}]
set version_generate_href   [export_vars -base version-generate-info {version_id}]

if {[apm_package_installed_p $package_key]
    && [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"]
} {
    set sitewide_admin_href "/acs-admin/package/$package_key/"
} else {
    set sitewide_admin_href ""
}

if { ![info exists installed_version_id] ||
     ($installed_version_id == $version_id && $distribution_uri eq "")
 } {
    # As long as there isn't a different installed version, and this package is being
    # generated locally, allow the user to write a specification file for this version
    # of the package.
    set version_write_href [export_vars -base version-generate-info {version_id {write_p 1}}]
}

if { $installed_p == "t" } {
    if { $distribution_uri eq "" } {
        # The distribution tarball was either (a) never generated, or (b) generated on this
        # system. Allow the user to make a tarball based on files in the filesystem.
        set generate_tarball_href [export_vars -base version-generate-tarball {version_id}]
    }

    append body "<ul>"

    if { [info exists can_disable_p] } {
        set version_disable_href [export_vars -base version-disable {version_id}]

    }
    if { [info exists can_enable_p] } {
        set version_enable_href [export_vars -base version-enable {version_id}]
    }

    if { $installed_p == "t" } {
        set package_delete_href [export_vars -base package-delete {version_id}]
    }        
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
