ad_page_contract {

    If no database driver is available, the acs-kernel libraries may not have
    been loaded (which is fine, since index.tcl will display a message
    instructing the user to install the database driver and restart the server
    before proceeding any further; in this case we won't use any procedures
    depending on the core libraries). Otherwise, all -procs.tcl files in
    acs-kernel (but not any -init.tcl files) will have been run.

    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Richard Li (richardl@arsdigita.com)
    @creation-date Mon Oct  9 15:19:31 2000
    @cvs-id $Id$
} {

}

if { [ns_queryexists done_p] } {
    # When installation is complete, the user is redirected to /index?done_p=1
    # (well, actually, /?done_p=1). This is so the user can just hit his/her
    # browser's Reload button to get the main OpenACS login page once (s)he's
    # restarted the OpenNSD.
    
  if { [ad_verify_install] } {
    install_return 200 "OpenACS Installation Complete" "

You have successfully installed the Open Architecture Community System (OpenACS)!

<p> Your server process has been terminated.  Unless you have configured your
web server to restart automatically, as outlined in the 
<a href=\"http://openacs.org/doc/openacs-4/\">OpenACS 4.x Installation Guide</a>, 
you will need to start your web server again.
When the web server restarts, OpenACS will be fully functional and you can reload 
this page to access the running web server.
"
    ns_shutdown
  } else {
    install_return 200 "Error" "
The installation program has encounted an error.  Please drop your OpenACS tablespace
and the OpenACS username, recreate them, and try again.  You can log this as a bug
using the <a href=\"http://openacs.org/bugtracker/openacs\">OpenACS Bug Tracker</a>. 
"
   return
  }
  return
}

set body "

Thank you for installing the Open Architecture Community System (OpenACS),
a suite of fully-integrated enterprise-class solutions
for collaborative commerce.
This is the OpenACS Installer which performs all the steps necessary
to get the OpenACS Community System running on your server.<p>
Please read the <a href=\"/doc/release-notes\">Release Notes</a> 
before proceeding to better understand what is contained in this release.

"

if { [file exists [apm_install_xml_file_path]] } {

    # Parse the xml document
    set root_node [apm_load_install_xml_file]

    if { [xml_node_get_name $root_node] ne "application" } {
        error "Installer: Could not find root node application in install.xml file"
    }

    set acs_application(name) [apm_required_attribute_value $root_node name]
    set acs_application(pretty_name) [apm_attribute_value -default $acs_application(name) $root_node pretty-name]
    set acs_application(home) [apm_attribute_value -default "" $root_node home]
    set acs_application(min_stack_size) [apm_attribute_value -default 128 $root_node min_stack_size]
    append body "<p>
The installer will automatically install the $acs_application(pretty_name)
application after the basic OpenACS tookit has been installed.
"

    if { $acs_application(home) ne "" } {
        append body [subst {<p>
For more information about the $acs_application(pretty_name) application visit the
<a href="[ns_quotehtml $acs_application(home)]">$acs_application(pretty_name) home page</a>
	}
    }
} else {
    set acs_application(name) openacs
    set acs_application(pretty_name) OpenACS
    set acs_application(home) ""
    set acs_application(min_stack_size) 128
}

set error_p 0

# do some error checking.
if { [nsv_exists acs_properties database_problem] } {
    # This NSV entry is set if there's some sort of problem with the database
    # driver. We aren't going to get very far in that case.

    append body "<p>
[nsv_get acs_properties database_problem]

<p><b>The first step involved in setting up your OpenACS
installation is to configure your RDBMS, correctly install a database driver,
and configure AOLserver to use it.  You can download 
and install the latest version of the AOLserver Oracle and PostgreSQL drivers
from the <a href='http://openacs.org/software'>OpenACS.org Software Page</a>.

<p>
Once you're sure everything is installed and configured correctly, restart AOLserver.</b></p>
"
    install_return 200 "Error" $body
    return
} 

#
# Unset array errors, in case it exists
#
if {[array exists errors]} {array unset errors}

# Perform database-specific checks
db_installer_checks errors error_p

if { !$error_p } {
    append body "<p>Your [db_name] driver is correctly installed and configured.\n"
}


# OpenNSD must support ns_sha1
if { [catch { ns_sha1 quixotusishardcore }] } {
    append errors "<li><p><b>The ns_sha1 function is missing. This function is
    required in OpenACS 4.x so that passwords can be securely stored in
    the database.</b></p>"

    set error_p 1
}

# OpenNSD must support Tcl 8.x
if { [info tclversion] < 8.5 } {
    append errors " <li><p><strong> You are using a version of Tcl less than 8.5.  You must use Tcl version 8.5
    or newer for OpenACS to work.  Probably your <code>nsd</code> executable is linked to an older version of Tcl.
    "
    set error_p 1
}
 
# AOLserver must support ns_cache.
if {[llength [info commands ns_cache]] < 1} {
    append errors "<li><p><strong>The <code>ns_cache</code> module is not installed.  This is required for OpenACS."
    set error_p 1
}

# AOLserver must have XML parsing.
if {![xml_support_ok xml_status_msg]} {
    append errors "Problems with XML support for AOLserver:<p> $xml_status_msg"
    set error_p 1
} 

# AOLserver must support the "fancy" ADP parser.
set adp_support [ns_config "ns/server/[ns_info server]/adp" DefaultParser]
if {$adp_support ne "fancy" && [ns_info name] ne "NaviServer"} {
    append errors "<li><p><strong>The fancy ADP parser is not enabled.  This is required to support 
the OpenACS Templating System.  Without this templating system, none of the OpenACS pages installed by default
will display.  Please add the following to your AOLserver configuration file (usually in 
<code>/home/aol30/yourservname.ini</code>) or see the <a href=\"/doc/install-guide/\">Installation Guide</a> for 
more information.<p>
<blockquote><pre>
\[ns/server/bquinn/adp\] 
Map=/*.adp 
DefaultParser=fancy
</blockquote></pre>
After adding support for the fancy ADP parser, please restart your web server.
</strong></p>"
    set error_p 1
}   

# AOLserver must have a large stack size (at least 128K by default, or the value specified
# in the install.xml file)

set stacksize [ns_config "ns/threads" StackSize]

if { ![string is integer $stacksize]
     || $stacksize < $acs_application(min_stack_size) * 1024
 } {
    append errors "<li><p><strong>The configured AOLserver Stacksize is too small, missing, or a non-integer value.
$acs_application(pretty_name) requires a StackSize parameter of at least
${acs_application(min_stack_size)}K.
<p>Please add the following line to your .tcl configuration file
<blockquote><pre>
ns_section \"ns/threads\"
        ns_param StackSize \[expr {${acs_application(min_stack_size)}*1024}\]
</blockquote></pre>
After adding support the larger stacksize, please restart your web server.
</strong></p>"
    set error_p 1
}   


# APM needs to check its permissions.
if { [catch {apm_workspace_dir} ] } {
    append errors "<li><p><strong>The $::acs::rootdir directory has incorrect permissions.  It must be owned by
the user executing the web server, normally <code>nsadmin</code>, and the owner must have read and write privileges
on this directory.  You can correct this by running the following script as root.
To give another user access to the files, add them to <code>web</code> group.
<blockquote><pre>
groupadd nsadmin
chown -R nsadmin:nsadmin $::acs::rootdir
chmod -R ug+rw $::acs::rootdir
</pre></blockquote>
</strong></p>"
    set error_p 1
}

# We have the workspace dir, but what about the package root?
if { ![file writable [file join $::acs::rootdir packages]] } {
    append errors "<li><p><strong>The $::acs::rootdir/packages directory has incorrect permissions.  It must be owned by
    the user executing the web server, normally <code>nsadmin</code> and the owner must have read and write 
    privileges on this directory and all of its subdirectories.  You can correct this by running the following 
    script as root.
    To give another user access to the files, add them to <code>web</code> group.
    <blockquote><pre>
groupadd nsadmin
chown -R nsadmin:nsadmin $::acs::rootdir/packages
chmod -R ug+rw $::acs::rootdir/packages
    </pre></blockquote></strong></p>"
    set error_p 1
}

db_helper_checks errors error_p

# Now that we know that the database and AOLserver are set up
# correctly, let's check out the actual db.
if {$error_p} {
    append body [subst {<p>
	<strong>At least one misconfiguration was discovered that must be corrected.
        Please fix all of them, restart the web server, and try running the OpenACS installer again.
	You can proceed without resolving these errors, but the system may not function
	correctly.
	</strong>
	<p>
	<ul>
	$errors
	</ul>
	<p>
    }]
}

# See whether the data model appears to be installed or not. The very first
# thing to be installed is the apm_packages table - does that exist?
if { ![db_table_exists apm_packages] } {
    # Nope. Need to install the data model.

    # Get the default for system_url. First try to get it from the nssock
    # hostname setting - if that is not available then try ns_info
    if { [catch {
	set driversection [ns_driversection]
        set system_url "http://[ns_config $driversection hostname [ns_info hostname]]"
        set system_port [ns_config $driversection port [ns_conn port]]

        # append port number if non-standard port
        if { !($system_port == 0 || $system_port == 80) } {
            append system_url ":$system_port"
        }

    }] } {
        set system_url "http://yourdomain.com"
    }

    set email_input_widget [install_input_widget -extra_attributes {id="email-addr"} email]
    append body "

<h2>System Configuration</h2>

We'll need to create a site-wide administrator for your server (like the root
user in UNIX). Please type in the email address, first and last name, and password
for this user.

<form action='installer/install' method='POST'>

<table>
<tr>
  <th span='3'>System Administrator</th>
</tr>

<tr>
  <th align='right'>Email:</th>
<td>$email_input_widget</td>
</tr>
<tr>
  <th align='right'>Username:</th>
  <td>[install_input_widget username]</td>
</tr>
<tr>
  <th align='right'>First Name:</th>
  <td>[install_input_widget first_names]</td>
</tr>
<tr>
  <th align='right'>Last Name:</th>
  <td>[install_input_widget last_name]</td>
</tr>
<tr>
  <th align='right'>Password:</th>
  <td>[install_input_widget -size 12 -type password password]</td>
</tr>
<tr>
  <th align='right'>Password (again):</th>
  <td>[install_input_widget -size 12 -type password password_confirmation]</td>
</tr>

<tr>
  <th span=3>&nbsp;</th>
</tr>

<tr>
  <th align='right'>System URL:</th>
  <td>[install_input_widget -value $system_url system_url]<br>
The canonical URL of your system as visible from the outside world<br>
Usually it should include the port if your server is not on port 80<br><br>
</tr>
<tr>
  <th align='right'>System Name:</th>
  <td>[install_input_widget -value "yourdomain Network" system_name]<br>
The name of your system.<br><br>
</tr>
<tr>
  <th align='right'>Publisher Name:</th>
  <td>[install_input_widget -value "Yourdomain Network, Inc." publisher_name]<br>
The legal name of the person or corporate entity responsible for the site.<br><br>
</tr>
<tr>
  <th align='right'>System Owner:</th>
  <td>[install_input_widget system_owner]<br>
The email address signed at the bottom of user-visible pages.<br><br>
</tr>
<tr>
  <th align='right'>Admin Owner:</th>
  <td>[install_input_widget admin_owner]<br>
The email address signed on administrative pages.<br><br>
</tr>
<tr>
  <th align='right'>Host Administrator:</th>
  <td>[install_input_widget host_administrator]<br>
A person whom people can contact if they experience technical problems.<br><br>
</tr>
<tr>
  <th align='right'>Outgoing Email Sender:</th>
  <td>[install_input_widget outgoing_sender]<br>
The email address that will sign outgoing alerts.
</tr>
<tr>
  <th align='right'>New Registration Email:</th>
  <td>[install_input_widget new_registrations]<br>
The email address to send New registration notifications.<br><br>
</tr>
</table>

<center>
<input type='submit' value='Start installation ->'>
</center>
</form>

<h4>\[*\] About username</h4>

<p>
  Once your server is installed, you can choose to have users login with username instead of email.
  This is particularly useful if you're authenticating against other services, such as LDAP or the 
  local operating system, which may not use email as the basis of authentication.
</p>

<script type='text/javascript'>
function updateSystemEmails() {
    var form = document.forms\[0\];
    
    form.system_owner.value = form.email.value;
    form.admin_owner.value = form.email.value;
    form.host_administrator.value = form.email.value;
    form.outgoing_sender.value = form.email.value;
    form.new_registrations.value = form.email.value;
}
var elem = document.getElementById('email-addr');
elem.addEventListener('change', function (event) {updateSystemEmails();});
</script>

    "
} else {
    # OK, apm_packages is installed - let's check out some other stuff too:
    if { ![install_good_data_model_p] } {
	append body "<p>It appears that the OpenACS data model is only partially installed.
	Please drop your tablespace and start from scratch."
    } else {
	append body "<p>The OpenACS data model is already installed. Click <i>Next</i> 
	to scan the available packages.

	[install_next_button "packages-install"]
	"
    }
}

install_return 200 "Welcome" $body

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
