ad_page_contract {

    Collects some basic information about the site.
    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$

} {
    email
}

# Get the default for system_url. First try to get it from the nssock
# hostname setting - if that is not available then try ns_info
# hostname, use yourdomain.com if that fails too.
if { [catch {
    set system_url "http://[ns_config "ns/server/[ns_info server]/module/nssock" hostname [ns_info hostname]]"

    # append port number if non-standard port
    if { !([ns_conn port] == 0 || [ns_conn port] == 80) } {
        append system_url ":[ns_conn port]"
    }

}] } {
    set system_url "http://yourdomain.com"
}

set body "

Please enter some information about your system.

<form action=site-info-2>
<blockquote>
<table>
<tr valign=baseline>
  <th align=right>System URL:</th>
  <td><input name=system_url size=40 value=\"$system_url\"><br>
The canonical URL of your system.<br><br>
</tr>
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
<tr valign=baseline>
  <th align=right>New Registration Email:</th>
  <td><input name=new_registrations size=40 value=\"$email\"><br>
The email address to send New registration notifications.<br><br>
</tr>
</table>

</blockquote>

<center>
<input type=submit value=\"Set System Information ->\">
</center>
</form>
"

install_return 200 "Set System Information" $body
