ad_page_contract { 
    Edits information for a version of a package.
    
    @param version_id The id of the package to process.
    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}
}

db_1row apm_all_version_info {}

doc_body_append "[apm_header -form "action=\"version-edit-2\" method=post" [list "version-view?version_id=$version_id" "$pretty_name $version_name"] "Edit a Version"]

"

# If the version name is incorporated into the version URL (it will almost always be!)
# then generate some JavaScript to automatically update the version URL when the
# version name changes.

set version_name_index [string first $version_name $version_uri]
if { $version_name_index >= 0 } {
    set version_uri_prefix [string range $version_uri 0 [expr { $version_name_index - 1 }]]
    set version_uri_suffix [string range $version_uri [expr { $version_name_index + [string length $version_name] }] end]

    doc_body_append "
<script language=javascript>
function updateVersionURL() {
    var form = document.forms\[0\];
    form.version_uri.value = '$version_uri_prefix' + form.version_name.value + '$version_uri_suffix';
}
</script>
"
    set version_name_on_change "onChange=\"updateVersionURL()\""
} else {
    set version_name_on_change ""
}

doc_body_append "
<script language=javascript>
function checkMailto(element) {
    // If it looks like an email address without a mailto: (contains an @ but
    // no colon) then prepend 'mailto:'.
    if (element.value.indexOf('@') >= 0 && element.value.indexOf(':') < 0)
        element.value = 'mailto:' + element.value;
}
</script>

[export_form_vars version_id release_date]

<table>

<tr>
  <th align=right nowrap>Package Key:</th>
  <td><tt>$package_key</tt></td>
</tr>
<tr>
  <th align=right nowrap>Package URL:</th>
  <td>$package_uri</td>
</tr>

<tr>
  <th align=right nowrap>Package Name:</th>
  <td>$pretty_name</td>
</tr>

<tr>
  <th align=right nowrap>OpenACS Core:</th>
  <td>$initial_install_p</td>
</tr>

<tr>
  <th align=right nowrap>Singleton:</th>
  <td>$singleton_p</td>
</tr>

<tr>
  <th align=right nowrap>Auto-mount:</th>
  <td><input name=auto_mount size=30 value=\"$auto_mount\" /></td>
</tr>

<tr>
  <td></td>
  <td>To create a new version of the package, type a new version number and
update the version URL accordingly. Leave the version name and URL alone to
edit the information regarding existing version of the package.</td>
</tr>

<tr>
  <th align=right nowrap>Version:</th>
  <td><input name=version_name size=10 value=\"$version_name\" $version_name_on_change>
</td>
</tr>

<tr>
  <th align=right nowrap>Version URL:</th>
  <td><input name=version_uri size=60 value=\"$version_uri\"></td>
</tr>

<tr valign=top>
  <th align=right><br>Summary:</th>
  <td><textarea name=summary cols=60 rows=2 wrap=soft>[ns_quotehtml $summary]</textarea></td>
</tr>

<tr valign=top>
  <th align=right><br>Description:</th>
  <td><textarea name=description cols=60 rows=5 wrap=soft>[ns_quotehtml $description]</textarea><br>
This description is <select name=description_format>
<option value=text/html [ad_decode $description_format "text/plain" "" "selected"]>HTML-formatted.
<option value=text/plain [ad_decode $description_format "text/plain" "selected" ""]>plain text.
</select>
</td>
</tr>
"

# Dynamic package version attributes
array set all_attributes [apm::package_version::attributes::get_spec]
array set attributes [apm::package_version::attributes::get \
                          -version_id $version_id \
                          -array attributes]
foreach attribute_name [array names all_attributes] {
    array set attribute $all_attributes($attribute_name)

    if { [info exists attributes($attribute_name)] } {
        # Attribute is already in db
        set attribute_value $attributes($attribute_name)
    } else {
        # The attribute is not in the db yet
        set attribute_value [apm::package_version::attributes::default_value $attribute_name]
    }

    doc_body_append "
<tr>
  <th align=right nowrap>${attribute(pretty_name)}:</th>
  <td><input name=\"$attribute_name\" size=\"30\" value=\"$attribute_value\">
</td>
</tr>
"
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

    doc_body_append "
<tr>
  <th align=right nowrap>$prompt:</th>
  <td><input name=owner_name size=30 value=\"$owner_name\"></td>
</tr>
<tr>
  <th align=right nowrap>$prompt URL:</th>
  <td><input name=owner_uri size=30 value=\"$owner_uri\" onChange=\"checkMailto(this)\"></td>
</tr>
"
}

doc_body_append "
<tr>
  <th align=right nowrap>Vendor:</th>
  <td><input name=vendor size=30 value=\"$vendor\"></td>
</tr>
<tr>
  <th align=right nowrap>Vendor URL:</th>
  <td><input name=vendor_uri size=60 value=\"$vendor_uri\"></td>
</tr>
"

doc_body_append "
<tr>
  <td></td>
  <td>
    <table><tr valign=baseline><td><input type=checkbox name=upgrade_p value=1 checked></td><td>
Upgrade the local package $pretty_name to this version and supersede older versions.
  </td></tr></table>
  </td>
</tr>

<tr>
  <td colspan=2 align=center><br>
<input type=submit value=\"Save Information\">
</td>
</tr>

</table>
</form>
[ad_footer]
"

