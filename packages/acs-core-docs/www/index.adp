<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">

<html>
<head>
<title>ACS Documentation</title>
<link rel="stylesheet" type="text/css" href="ad.css">
</head>

<body bgcolor="#ffffff">
<blockquote>

<table>
<tr><td valign="bottom">
<a href="http://www.arsdigita.com/"><img src="http://www.arsdigita.com/graphics/ad_logo_big.gif" align="left" border="0"></a>
</td>
<td valign="bottom">
<h1>The ArsDigita Community System (ACS)</h1>
</td></tr>
</table>

<table border="1" cellpadding="8" cellspacing="0" width="80%">

<tr>
<td class="codeblock"><strong>The Basic ACS</strong>
</td>
<td class="codeblock"><strong>Installed Packages</strong></td>
</tr>

<tr><td valign="top">
<pre><strong>For Everyone</strong>
        - <a href="release-notes.html">ACS 4.2 beta Release Notes</a>
        - <a href="http://developer.arsdigita.com/doc/release-notes/">Older Release Notes</a>

<a href="acs-admin.html"><strong>For ACS-admins</strong></a>
	- <a href="unix-install.html">Unix Installation Guide</a>
        - <a href="win-install.html">Windows Installation Guide</a>
        - <a href="http://www.arsdigita.com/acs-repository/">ACS Repository</a>

<a href="acs-dev.html"><strong>For Developers</strong></a>
	- <a href="kernel-doc.html">Kernel Documentation</a>
	- <a href="dev-guide.html">Developers Guide</a>
	- <a href="eng-standards.html">Engineering Standards</a>
        - <a href="/api-doc/">API Browser</a> for this ACS instance
	- <a href="more-developer-info.html">Other Developer Resources</a>

<strong>Primers and References</strong>
        - <a href="http://aolserver.com/docs/">AOLserver Documentation</a> 
	  (the <a href="http://aolserver.com/docs/tcldev/tcldev.htm">Tcl Developer's Guide</a> in particular.)
        - <a href="http://www.arsdigita.com/books/tcl/">Tcl for Web Nerds</a>
        - <a href="http://www.arsdigita.com/books/sql/">SQL for Web Nerds</a>
</pre></td>

<td valign="top">
<pre>
<% 
# This block of ADP code ensures that the Installer can still serve this
# page even without a working templating system.

set found_p 0

if {[db_table_exists apm_package_types]} {
    db_foreach get_installed_pkgs "select package_key, pretty_name from apm_package_types" {
        set found_p 1
	set index_page [lindex [glob -nocomplain \
				  "[acs_package_root_dir $package_key]/www/doc/index.*"] 0]
  	
        if { [file exists $index_page] } {
	    if {![empty_string_p $pretty_name]} {
	       adp_puts "- <a href=\"/doc/$package_key/\">$pretty_name</a>\n"
	    } else {
	       adp_puts "- <a href=\"/doc/$package_key/\">$package_key</a>\n"
	    }
     }
  }
}



if {!$found_p} {
    adp_puts "- No installed packages.\n"
}

%>
</pre>
</td>
</tr>
</table>


<br><br>
<span class="force">This software is mostly Copyright 1995-2000 ArsDigita Corporation<br>
and licensed under the
<a href="license.text">GNU General Public License, version 2 (June 1991)</a></span>
<p class="force">
Questions or comments about the documentation? 
<br>
Please visit the
<a href="http://developer.arsdigita.com/docbook/">Documentation Central</a>
or shoot at <a href="mailto:claus@arsdigita.com">claus@arsdigita.com</a>.
</p>
</blockquote>
</body>
</html>