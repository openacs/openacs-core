ad_page_contract {

    Collects some basic information about the site.
    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {
    email
}

set body "

Please enter some information about your system.

<form action=site-info-2>
<blockquote>
<table>
<tr valign=baseline>
  <th align=right>System Name:</th>
  <td><input name=system_name size=40 value=\"yourdomain Network\"><br>
The name of your system.<br><br>
</tr>
<tr valign=baseline>
  <th align=right>Publisher Name:</th>
  <td><input name=publisher_name size=40 value=\"Yourdomain Network, Inc.\"><br>
The legal name of the person or corporate entity responsible for the site.<br><br>
</tr>
<tr valign=baseline>
  <th align=right>System Owner:</th>
  <td><input name=system_owner size=40 value=\"$email\"><br>
The email address signed at the bottom of user-visible pages.<br><br>
</tr>
<tr valign=baseline>
  <th align=right>Admin Owner:</th>
  <td><input name=admin_owner size=40 value=\"$email\"><br>
The email address signed on administrative pages.<br><br>
</tr>
<tr valign=baseline>
  <th align=right>Host Administrator:</th>
  <td><input name=host_administrator size=40 value=\"$email\"><br>
A person whom people can contact if they experience technical problems.<br><br>
</tr>
<tr valign=baseline>
  <th align=right>Outgoing Email Sender:</th>
  <td><input name=outgoing_sender size=40 value=\"$email\"><br>
The email address that will sign outgoing alerts.
</tr>
</table>

</blockquote>

<center>
<input type=submit value=\"Set System Information ->\">
</center>

"

install_return 200 "Set System Information" $body
