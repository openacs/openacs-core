ad_page_contract {
    Adds a package to the package manager.
    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
}

set user_id [ad_verify_and_get_user_id]

db_1row apm_get_name { 
    select first_names || ' ' || last_name user_name, email from cc_users where user_id = :user_id
}

set package_id [db_nextval acs_object_id_seq]
set version_id [db_nextval acs_object_id_seq]
db_release_unused_handles

doc_body_append "[apm_header -form "action=package-add-2 method=post" "Add a New Package"]
[export_form_vars package_id version_id]


<script language=javascript>
function updateURLs() {
    // Update the package and version URL, if the package key and/or version name change.
    var form = document.forms\[0\];
    if (form.package_uri.value == '')
        form.package_uri.value = 'http://openacs.org/repository/apm/packages/' + form.package_key.value;
    if ((form.version_name.value != '') && (form.version_uri.value == ''))
        form.version_uri.value = 'http://openacs.org/repository/download/apm/' + form.package_key.value + '-' + form.version_name.value + '.apm';
}
</script>

<script language=javascript>
function checkMailto(element) {
    // If it looks like an email address without a mailto: (contains an @ but
    // no colon) then prepend 'mailto:'.
    if (element.value.indexOf('@') >= 0 && element.value.indexOf(':') < 0)
        element.value = 'mailto:' + element.value;
}
</script>

<table>

<tr>
  <td></td>
  <td>Select a package key for your package. This is a unique, short, and lower-case identifier
for your package containing only letters, numbers, and hyphens (e.g., <tt>address-book</tt>
for the address book package or <tt>photo-album</tt> for the Photo Album).
Files for your package will be placed in a directory with this name.</td>
</tr>

<tr>
  <th align=right nowrap>Package Key:</th>
  <td><input name=package_key size=30 onChange=\"updateURLs()\"></td>
</tr>

<tr>
  <td></td>
  <td>Select a short, human-readable name for your package, e.g., \"Address Book\" or
\"Photo Album.\"
</tr>

<tr>
  <th align=right nowrap>Package Name:</th>
  <td><input name=pretty_name size=30></td>
</tr>

<tr>
  <td></td>
  <td>Please indicate the plural form of the package name, e.g. the plural form of 'Bboard' is 'Bboards.'
</tr>

<tr>
  <th align=right nowrap>Package Plural:</th>
  <td><input name=pretty_plural size=40></td>
</tr>


<tr>
  <td></td>
  <td>Indicate whether this package is an application or a service.   
  Applications are software intended for end-users, e.g. Bboard.
  Services are system-level software that extend OpenACS to provide new system-wide functionality,
  e.g. Workflow.
</tr>
<tr>
  <th align=right nowrap>Package Type:</th>
  <td><select name=package_type>
      <option value=apm_application>Application
      <option value=apm_service>Service
      </select>
   </td>
   </tr>
</tr>
<tr>
  <th align=right nowrap>OpenACS Core?</th>
  <td><input type=checkbox name=initial_install_p value=t> Is your package part of the OpenACS Core that
forms the set of packages initially installed?  If you're not part of the OpenACS Core development team,
it would be best if you'd leave this box unchecked.
</tr>
<tr>
  <th align=right nowrap>Singleton?</th>
  <td><input type=checkbox name=singleton_p value=t> Is your package a singleton package?  Singleton packages
can have at most one instance; attempts to create more instances of the singleton will return the currently
created instance.  Singleton packages are appropriate for services that should not have multiple instances,
such as the ACS Kernel.
</tr>
<tr>
  <th align=right nowrap>Auto-mount URI</th>
  <td><input name=auto_mount size=30></td>
</tr>

<tr>
  <td></td>
  <td>The URI (name) under the main site where the package will automatically be
      mounted upon installation. This feature is typically only used by singleton packages.</td>
</tr>

<tr>
  <td></td>
  <td>Pick a canonical URL for your package. This should be a URL where the package can be downloaded.
</tr>

<tr>
  <th align=right nowrap>Package URL:</th>
  <td><input name=package_uri size=60></td>
</tr>

<tr>
  <td></td>
  <td>Select an initial version number for the package. By convention, this is
<tt>0.1d</tt> if you are just starting to create your package, or
<tt>4.0</tt> if you are creating your package from ACS 4.0 code.  The version number
must fit the format of <strong>major number</strong>.<strong>minor number</strong> with 
an optional suffix of <strong>d</strong> for development, <strong>a</strong> for alpha, or 
<strong>b</strong> for beta.
</tr>

<tr>
  <th align=right nowrap>Initial Version:</th>
  <td><input name=version_name size=10 onChange=\"updateURLs()\"></td>
</tr>

<tr>
  <td></td>
  <td>Pick a canonical URL for the initial version of the package. For now, the default
will always be correct.</td>
</tr>

<tr>
  <th align=right nowrap>Version URL:</th>
  <td><input name=version_uri size=60></td>
</tr>

<tr>
  <td></td>
  <td>Type a brief, one-sentence-or-less summary of the functionality of your package.
In general, this should be similar to the text introducing the
<a href=\"/doc/\">developer documentation</a>. The summary should begin
with a capital letter and end with a period.
</td>
</tr>

<tr valign=top>
  <th align=right><br>Summary:</th>
  <td><textarea name=summary cols=60 rows=2 wrap=soft></textarea></td>
</tr>

<tr>
  <td></td>
  <td>Type a one-paragraph description of your package. This is probably analogous to the
first paragraph in your package's documentation.</td>
</tr>

<tr valign=top>
  <th align=right><br>Description:</th>
  <td><textarea name=description cols=60 rows=5 wrap=soft></textarea><br>
This description is <select name=description_format>
<option value=text/html>HTML-formatted.
<option value=text/plain>plain text.
</select>
</td>
</tr>

<tr>
  <td></td>
  <td>Enter the names and URLs of up to two people who own the package.
These should be entered in order of importance: whoever works most heavily
on the package should be first. You'll probably want to use email addresses
for URLs, in which case you should precede them with <tt>mailto:</tt> (e.g.,
<tt>mailto:developername@openacs.org</tt>).
</tr>

<tr>
  <th align=right nowrap>Primary Owner:</th>
  <td><input name=owner_name size=30 value=\"$user_name\"></td>
</tr>
<tr>
  <th align=right nowrap>Primary Owner URL:</th>
  <td><input name=owner_uri size=30 value=\"mailto:$email\" onChange=\"checkMailto(this)\"></td>
</tr>
<tr>
  <th align=right nowrap>Secondary Owner:</th>
  <td><input name=owner_name size=30></td>
</tr>
<tr>
  <th align=right nowrap>Secondary Owner URL:</th>
  <td><input name=owner_uri size=30 onChange=\"checkMailto(this)\"></td>
</tr>

<tr>
  <td></td>
  <td>If the package is being released by a company, type in its name and URL here.
<!-- ArsDigita employees should <a href=\"javascript:document.forms\[0\].vendor.value='ArsDigita Corporation';document.forms\[0\].vendor_uri.value='http://www.arsdigita.com/';void(0)\">click here</a> to fill this in automatically.</td> -->
</tr>

<tr>
  <th align=right nowrap>Vendor:</th>
  <td><input name=vendor size=30></td>
</tr>
<tr>
  <th align=right nowrap>Vendor URL:</th>
  <td><input name=vendor_uri size=60></td>
</tr>

<tr>
  <td></td>
  <td>
    <table><tr valign=baseline><td><input type=checkbox name=install_p value=1 checked></td><td>
Write a package specification file for this package.
(You almost certainly want to leave this checked.)</td></tr></table>
  </td>
</tr>

<tr>
  <td colspan=2 align=center><br>
Click \"Create Package\" to register your package.  If there are data models for
this package, please load them manually into your database.
<p><input type=submit value=\"Create Package\">
</td>
</tr>

</table>

[ad_footer]
"





