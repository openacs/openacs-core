<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">

<html>
<head>
<title>OpenACS Documentation</title>
<link rel="stylesheet" type="text/css" href="openacs.css">
</head>

<body bgcolor="#ffffff">
<blockquote>

<table>
<tr><td valign="bottom">
<a href="http://www.openacs.org/"><img src="images/alex.jpg" align="left" border="0"></a>
</td>
<td valign="bottom">
<h1>The Open Architecture Community System</h1>
</td></tr>
</table>

<table border="1" cellpadding="8" cellspacing="0" width="80%">

<tr>
<td class="codeblock"><strong>Basic OpenACS</strong>
</td>
<td class="codeblock"><strong>Package Documentation</strong></td>
</tr>

<tr><td valign="top">
<pre><strong>Getting Started</strong>
        - <a href="release-notes.html">OpenACS 4.6.3 Release Notes</a>
	- <a href="individual-programs.html">Required Software</a>
	- <a href="unix-install.html">Unix Installation Guide</a>
        - <a href="win2k-installation.html">Windows Installation Guide</a>
	- <a href="mac-installation.html">Mac OS X Installation Guide</a>
	- <a href="upgrade.html">Upgrading</a>
	- <a href="tutorial.html">Developer Tutorial</a>
        - <a href="/api-doc/">API Browser</a> for this OpenACS instance

<strong><a href="index.html">Full Table of Contents</a>

<strong>Primers and References</strong>

        - <a href="http://aolserver.com/docs/">AOLserver Documentation</a> 
	  (the <a href="http://aolserver.com/docs/devel/tcl/api/">Tcl Developer's Guide</a> in particular.)
        - <a href="http://philip.greenspun.com/tcl/">Tcl for Web Nerds</a>
        - <a href="http://philip.greenspun.com/sql/">SQL for Web Nerds</a>
</pre></td>

<td valign="top">
<pre>
<% 
# This block of ADP code ensures that the Installer can still serve this
# page even without a working templating system.

set found_p 0

if {[db_table_exists apm_package_types]} {
    db_foreach get_installed_pkgs "select package_key, pretty_name from apm_package_types order by upper(pretty_name) " {
        if { ! $found_p } { 
           set found_p 1
           adp_puts "<strong>Installed Packages</strong>\n\n"
        }
	set index_page [lindex [glob -nocomplain \
				  "[acs_package_root_dir $package_key]/www/doc/index.*"] 0]
  	
        if { [file exists $index_page] } {
	    if {![empty_string_p $pretty_name]} {
	       adp_puts "- <a href=\"/doc/$package_key/\">$pretty_name</a>\n"
	    } else {
	       adp_puts "- <a href=\"/doc/$package_key/\">$package_key</a>\n"
	    }
        } else { 
            if {![empty_string_p $pretty_name]} {
	       adp_puts "- $pretty_name\n"
	    } else {
	       adp_puts "- $package_key\n"
            }
        }
    }
}


if {!$found_p} {
    adp_puts "- No installed packages.\n"
}

set packages [core_docs_uninstalled_packages]
if { ! [empty_string_p $packages] } { 
  adp_puts "\n<strong>Uninstalled packages</strong>\n\n"
  foreach {key name} $packages { 
    set index_page [lindex [glob -nocomplain \
				  "[acs_package_root_dir $key]/www/doc/index.*"] 0]
    if { [file exists $index_page] } {
       adp_puts "- <a href=\"$key\">$name</a>\n"
    } else { 
       adp_puts "- $name\n"
    }
  }
}
%>
</pre>
</td>
</tr>
</table>


<br><br>
<span class="force">This software is mostly Copyright 1995-2000 ArsDigita Corporation<br>
and licensed under the
<a href="http://www.gnu.org/licenses/gpl.txt">GNU General Public License, version 2 (June 1991)</a></span>
<p class="force">
Questions or comments about the documentation? 
<br>
Please visit the
<a href="http://openacs.org/forums/">OpenACS forums</a>
or shoot email at <a href="mailto:vinod@kurup.com">vinod@kurup.com</a> or rmello at fslc.usu.edu.
</p>
</blockquote>
</body>
</html>
