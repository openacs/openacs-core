<master>
<center>
<table border="0" cellpadding="8" cellspacing="0" width="80%">

<tr><td valign="top" align="left">
<h3>OpenACS Core Documentation</h3>
<ul>
<li><a href="for-everyone.html">Part I: For Everyone</a>
<li><a href="acs-admin.html">Part II: Administrator's Guide</a>
<li><a href="acs-package-dev.html">Part III: Package Developer's Guide</a>
<li><a href="acs-plat-dev.html">Part IV: Platform Developer's Guide</a>
</ul>

<h3>Primers and References</h3>
<ul>

<li><a href="/api-doc/">API Browser</a>
<li><a href="http://cvs.openacs.org/">OpenACS CVS Browser</a>
<li><a href="http://openacs.org/storage/index?folder_id=2855304">OpenACS tutorial</a>
<li><a href="http://openacs.org/faq/">OpenACS FAQs</a>
<li><a href="http://openacs.org/education/">Learning OpenACS</a>
<li><a href="http://aolserver.com/docs/">AOLserver Documentation</a>
	  (the <a href="http://aolserver.com/docs/devel/tcl/api/">Tcl Developer's Guide</a> in particular.)
<li><a href="http://philip.greenspun.com/tcl/">Tcl for Web Nerds</a>
<li><a href="http://philip.greenspun.com/sql/">SQL for Web Nerds</a>
</ul>

<h3>Documentation Improvement Project</h3>
<ul>
<li><a href="http://openacs.org/projects/openacs/doc-project/">Help improve OpenACS documentation</a>
</ul>

</td>

<td valign="top" align="left">
<% 
# This block of ADP code ensures that the Installer can still serve this
# page even without a working templating system.

set found_p 0

if {[db_table_exists apm_package_types]} {
    db_foreach get_installed_pkgs "select package_key, pretty_name from apm_package_types order by upper(pretty_name) " {
        if { ! $found_p } { 
           set found_p 1
           adp_puts "\n<h3>Installed Packages</h3>\n<ul>\n"
        }
	set index_page [lindex [glob -nocomplain \
				  "[acs_package_root_dir $package_key]/www/doc/index.*"] 0]
  	
        if { [file exists $index_page] } {
	    if {![empty_string_p $pretty_name]} {
	       adp_puts "<li><a href=\"/doc/$package_key/\">$pretty_name</a>\n"
	    } else {
	       adp_puts "<li><a href=\"/doc/$package_key/\">$package_key</a>\n"
	    }
        } else { 
            if {![empty_string_p $pretty_name]} {
	       adp_puts "<li>$pretty_name\n"
	    } else {
	       adp_puts "<li>$package_key\n"
            }
        }
    }
}


if {!$found_p} {
    adp_puts "<li> No installed packages.\n"
}
    adp_puts "</ul>"

set packages [core_docs_uninstalled_packages]
if { ! [empty_string_p $packages] } { 
  adp_puts "\n<h3>Uninstalled packages</h3>\n<ul>"
  foreach {key name} $packages { 
    set index_page [lindex [glob -nocomplain \
				  "[acs_package_root_dir $key]/www/doc/index.*"] 0]
    if { [file exists $index_page] } {
       adp_puts "<li> <a href=\"$key\">$name</a>\n"
    } else { 
       adp_puts "<li> $name\n"
    }
  }
  adp_puts "\n</ul>"
}
%>
</td>
</tr>
</table>

<p class="force">This software is licensed under the
<a href="http://www.gnu.org/licenses/gpl.txt">GNU General Public License, version 2 (June 1991)</a></p>
<p class="force">
Questions or comments about the documentation? 
<br>
Please visit the
<a href="http://openacs.org/forums/">OpenACS forums</a> or send email to <a href="mailto:docs@openacs.org">docs@openacs.org</a>.
</p>

</center>
