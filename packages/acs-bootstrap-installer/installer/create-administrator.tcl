ad_page_contract {

    Prompts the user to enter information used to create an administrator.
    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {}

if { ![install_good_data_model_p] } {
    install_return 200 "Data Model Not Installed" "

It appears that the data model is not yet installed. Please <a href=\"index\">go back
to the beginning and try again</a>.

"
    return
}

if { [db_0or1row user_exists "select email from cc_users where rownum = 1"] } {
    install_return 200 "Administrator Already Created" "

The site-wide administrator ($email) has already been created. Click the <i>Next</i>
button to set information about your site.

<center><form action=site-info>
[ad_export_vars -form email]
<input type=submit value=\"Next ->\">
</form>
</center>
"
    return
}

set body "

We'll need to create a site-wide administrator for your server (like the root
user in UNIX). Please type in the email address, first and last name, and password
for this user.

<form action=\"create-administrator-2\">
<blockquote>
<table>
<tr>
  <th align=right>Email:</th>
  <td><input name=email size=20></td>
</tr>
<tr>
  <th align=right>Username:</th>
<td><input name=username size=20> <span style=\"color: red;\">\[*\]</span>
  </td>
</tr>
<tr>
  <th align=right>First Name:</th>
  <td><input name=first_names size=20></td>
</tr>
<tr>
  <th align=right>Last Name:</th>
  <td><input name=last_name size=20></td>
</tr>
<tr>
  <th align=right>Password:</th>
  <td><input type=password name=password size=12></td>
</tr>
<tr>
  <th align=right>Password (again):</th>
  <td><input type=password name=password_confirmation size=12></td>
</tr>

<tr><td colspan=2 align=center><br><input type=submit value=\"Create User ->\"></td></tr>
</form>
</table>
</blockquote>

<h4>\[*\] About username</h4>

<p>
  Once your server is installed, you can choose to have users login with username instead of email.
  This is particularly useful if you're authenticating against other services, such as LDAP or the 
  local operating system, which may not use email as the basis of authentication.
</p>
"

install_return 200 "Create Administrator" $body
