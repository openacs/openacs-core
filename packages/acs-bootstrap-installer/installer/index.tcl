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
    exit
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
Please read the <a href=\"/doc/release-notes.html\">Release Notes</a> 
before proceeding to better understand what is contained in this release.

"

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
from the <a href='http://openacs.org/software.adp'>OpenACS.org Software Page</a>.

<p>
Once you're sure everything is installed and configured correctly, restart AOLserver.</b></p>
"
    install_return 200 "Error" $body
    return
} 

# Perform database-specific checks
db_installer_checks errors error_p

if { !$error_p } {
    append body "<p>Your [db_name] driver is correctly installed and configured.\n"
}


# OpenNSD must support ns_sha1
if { [catch { ns_sha1 quixotusishardcore }] } {
    append errors "<li><p><b>The ns_sha1 function is missing. This function is
    required in OpenACS 4.x so that passwords can be securely stored in
    the database. This function is available in the nssha1 module that is part of the <a
    href=\"http://www.arsdigita.com/aol3/\">ArsDigita server
    distribution</a>.</b></p>"

    set error_p 1
}

# OpenNSD must support Tcl 8.x
if { [string range [info tclversion] 0 0] < 8 } {
    append errors " <li><p><strong> You are using a version of Tcl less than 8.0.  You must use Tcl version 8.0
    for OpenACS to work.  Probably your <code>nsd</code> executable is linked to <code>nsd76</code>.  Please
    link it to <code>nsd8x</code> to fix this problem.  Please refer to the 
    <a href=\"/doc/install-guide/\">Installation Guide</a>.
    <blockquote><pre>
    ln -s /home/aol30/bin/nsd8x /home/aol30/nsd
    </pre></blockquote>
    "
    set error_p 1
}
 
# AOLserver must support ns_cache.
if {[llength [info commands ns_cache]] < 1} {
    append errors "<li><p><strong>The <code>ns_cache</code> module is not installed.  This
is required to support the OpenACS Security system.  Please make sure that <code>ns_cache</code>
is included in your module list.  An example module list is shown below:
file (usually in <code>/home/aol30/yourservername.ini</code>) or see the 
<a href=\"/doc/install-guide/\">Installation Guide</a> for more information.<p>
<blockquote><pre>
\[ns/server/bquinn/modules\] 
nssock=nssock.so 
nslog=nslog.so 
nssha1=nssha1.so
nscache=nscache.so
</blockquote></pre>
After adding <code>ns_cache</code>, please restart your web server.
</strong></p>"
    set error_p 1
} 

# AOLserver must have XML parsing.
if {![xml_support_ok xml_status_msg]} {
    append errors "Problems with XML support for AOLserver:<p> $xml_status_msg"
    set error_p 1
} 

# AOLserver must support the "fancy" ADP parser.
set adp_support [ns_config "ns/server/[ns_info server]/adp" DefaultParser]
if { [string compare $adp_support "fancy"] } {
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

# AOLserver must have a large stack size (at least 128K)
set stacksize [ns_config "ns/threads" StackSize]
if { $stacksize < [expr 128 * 1024] } {

    append errors "<li><p>The configured AOLserver Stacksize is too small ($stacksize).
OpenACS requires a StackSize parameter of at least 131072 (ie 128K).
Please add the following to your AOLserver configuration file or 
see the <a href=\"/doc/install-guide/\">Installation Guide</a> for more information.<p>
<blockquote><pre>
\[ns/threads\] 
stacksize=131072 
</blockquote></pre>
<p>If you use a .tcl configuration file, add
<blockquote><pre>
ns_section \"ns/threads\"
        ns_param StackSize [expr 128*1024]
</blockquote></pre>
After adding support the larger stacksize, please restart your web server.
</strong></p>"
    set error_p 1
}   


# APM needs to check its permissions.
if { [catch {apm_workspace_dir} ] } {
    append errors "<li><p><strong>The [acs_root_dir] directory has incorrect permissions.  It must be owned by
the user executing the web server, normally <code>nsadmin</code>, and the owner must have read and write priveliges
on this directory.  You can correct this by running the following script as root.
To give another user access to the files, add them to <code>web</code> group.
<blockquote><pre>
groupadd web
chown -R nsadmin:web [acs_root_dir]
chmod -R ug+rw [acs_root_dir]
</pre></blockquote>
</strong></p>"
    set error_p 1
}

# We have the workspace dir, but what about the package root?
if { ![file writable [file join [acs_root_dir] packages]] } {
    append errors "<li><p><strong>The [acs_root_dir]/packages directory has incorrect permissions.  It must be owned by
    the user executing the web server, normally <code>nsadmin</code> and the owner must have read and write 
    priveliges on this directory and all of its subdirectories.  You can correct this by running the following 
    script as root.
    To give another user access to the files, add them to <code>web</code> group.
<blockquote><pre>
groupadd web
chown -R nsadmin:web [acs_root_dir]/packages
chmod -R ug+rw [acs_root_dir]/packages
</pre></blockquote></strong></p>"
    set error_p 1
}

db_helper_checks errors error_p

# Now that we know that the database and aolserver are set up
# correctly, let's check out the actual db.
if {$error_p} {
    append body "<p>
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
"
}

# See whether the data model appears to be installed or not. The very first
# thing to be installed is the apm_packages table - does that exist?
if { ![db_table_exists apm_packages] } {
    # Nope. Need to install the data model.
    append body "<p>The next step is to install the OpenACS kernel data model. Click the <i>Next</i>
    button to proceed.
    
    [install_next_button "install-data-model"]
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
