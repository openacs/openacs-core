ad_page_contract { 
    Edits information for a version of a package.
    
    @param version_id The id of the package to process.
    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:naturalnum,notnull}
}

db_1row apm_all_version_info {
    select version_id, package_key, package_uri, pretty_name, version_name,
      version_uri, auto_mount, summary, description_format, description, release_date,
      vendor, vendor_uri, enabled_p, installed_p, tagged_p, imported_p,
      data_model_loaded_p, activation_date, tarball_length, 
      deactivation_date, distribution_uri, distribution_date, singleton_p,
      initial_install_p, implements_subsite_p, inherit_templates_p
    from apm_package_version_info where version_id = :version_id
}

set title "Edit a Version"
set context [list \
		 [list "/acs-admin/apm/" "Package Manager"] \
		 [list "version-view?version_id=$version_id" "$pretty_name $version_name"] \
		 $title]

set body "<form action='version-edit-2' method='post'>"

# If the version name is incorporated into the version URL (it will almost always be!)
# then generate some JavaScript to automatically update the version URL when the
# version name changes.

set version_name_index [string first $version_name $version_uri]
if { $version_name_index >= 0 } {
    set version_uri_prefix [string range $version_uri 0 $version_name_index-1]
    set version_uri_suffix [string range $version_uri $version_name_index+[string length $version_name] end]

    append body [subst {
<script type="text/javascript" nonce='$::__csp_nonce'>
function updateVersionURL() {
    var form = document.forms\[0\];
    form.version_uri.value = "$version_uri_prefix" + form.version_name.value + "$version_uri_suffix";
}
</script>}]
    template::add_event_listener -CSSclass "update-version-url" -event change -script {updateVersionURL();}
}

append body [subst {
<script type="text/javascript" nonce='$::__csp_nonce'>
function checkMailto(element) {
    // If it looks like an email address without a mailto: (contains an @ but
    // no colon) then prepend 'mailto:'.
    if (element.value.indexOf('@') >= 0 && element.value.indexOf(':') < 0)
        element.value = 'mailto:' + element.value;
}
</script>

[export_vars -form {version_id release_date}]

<table>

<tr>
  <th style="text-align:right; white-space: nowrap">Package Key:</th>
  <td><tt>$package_key</tt></td>
</tr>
<tr>
  <th style="text-align:right; white-space: nowrap">Package URL:</th>
  <td>$package_uri</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Package Name:</th>
  <td>$pretty_name</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">OpenACS Core:</th>
  <td>[ad_decode $initial_install_p t Yes No]</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Singleton:</th>
  <td>[ad_decode $singleton_p t Yes No]</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Implements Subsite:</th>
  <td>[ad_decode $implements_subsite_p t Yes No]</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Inherit Templates:</th>
  <td>[ad_decode $inherit_templates_p t Yes No]</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Auto-mount:</th>
  <td><input name="auto_mount" size="30" value="$auto_mount"></td>
</tr>

<tr>
  <td></td>
  <td>To create a new version of the package, type a new version number and
update the version URL accordingly. Leave the version name and URL alone to
edit the information regarding existing version of the package.</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Version:</th>
  <td><input name="version_name" size="10" value="$version_name" class="update-version-url">
</td>
</tr>

<tr>
  <th style="text-align:right; white-space: nowrap">Version URL:</th>
  <td><input name="version_uri" size="80" value="$version_uri"></td>
</tr>

<tr valign="top">
  <th style="text-align:right"><br>Summary:</th>
  <td><textarea name="summary" cols="60" rows="2">[ns_quotehtml $summary]</textarea></td>
</tr>

<tr valign="top">
  <th style="text-align:right"><br>Description:</th>
  <td><textarea name="description" cols="60" rows="5">[ns_quotehtml $description]</textarea><br>
This description is <select name="description_format">
<option value="text/html" [ad_decode $description_format "text/plain" "" "selected"]>HTML-formatted.
<option value="text/plain" [ad_decode $description_format "text/plain" "selected" ""]>plain text.
</select>
</td>
</tr>
}]

# Dynamic package version attributes
array set all_attributes [apm::package_version::attributes::get_spec]
array set attributes [apm::package_version::attributes::get \
                          -version_id $version_id \
                          -array attributes]
foreach attribute_name [array names all_attributes] {
    set attribute $all_attributes($attribute_name)

    if { [info exists attributes($attribute_name)] } {
        # Attribute is already in db
        set attribute_value $attributes($attribute_name)
    } else {
        # The attribute is not in the db yet
        set attribute_value [apm::package_version::attributes::default_value $attribute_name]
    }
    # provide default size
    if {![dict exists $attribute size]} {
	dict set attribute size 30
    }
    append body [subst {
<tr>
  <th style="text-align:right; white-space: nowrap">[dict get $attribute pretty_name]:</th>
  <td><input name="$attribute_name" size="[dict get $attribute size]" value="$attribute_value"></td>
</tr>
    }]
}

# Build a list of owners. Ensure that there are at least two.
set owners [db_list_of_lists apm_all_owners {
    select owner_name, owner_uri from apm_package_owners where version_id = :version_id
}]
if { [llength $owners] == 0 } {
    set owners [list [list "" ""]]
}

# Add an extra one, so an arbitrary number of owners can be assigned to the package.
lappend owners [list "" ""]

set counter 0
foreach owner_info $owners {
    set owner_name [lindex $owner_info 0]
    set owner_uri [lindex $owner_info 1]
    incr counter

    if { $counter <= 3 } {
	set prompt "[lindex { "" Primary Secondary Tertiary } $counter] Owner"
    } else {
	set prompt "Owner #$counter"
    }

    append body [subst {
<tr>
  <th style="text-align:right; white-space: nowrap">$prompt:</th>
  <td><input name="owner_name" size="30" value="$owner_name"></td>
</tr>
<tr>
  <th style="text-align:right; white-space: nowrap">$prompt URL:</th>
  <td><input name="owner_uri" size="30" value="$owner_uri" class="check-mailto"></td>
</tr>
    }]
}

append body [subst {
<tr>
  <th style="text-align:right; white-space: nowrap">Vendor:</th>
  <td><input name="vendor" size="30" value="$vendor"></td>
</tr>
<tr>
  <th style="text-align:right; white-space: nowrap">Vendor URL:</th>
  <td><input name="vendor_uri" size="60" value="$vendor_uri"></td>
</tr>
}]

append body [subst {
<tr>
  <td></td>
  <td>
    <table>
    <tr valign="baseline">
    <td><input type="checkbox" name="upgrade_p" value="1" checked></td>
    <td>Upgrade the local package $pretty_name to this version and supersede older versions.</td>
    </tr>
    </table>
  </td>
</tr>

<tr>
  <td colspan="2" align="center"><br>
  <input type="submit" value="Save Information">
  </td>
</tr>

</table>
</form>
}]

template::add_event_listener -CSSclass "check-mailto" -event change -script {checkMailto(this);}

ad_return_template apm

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
