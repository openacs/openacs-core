# A very special library used to support the ACS installer. Sourced only
# when there's no database driver available, or [ad_verify_install]
# returns false.
#
# If no database driver is available, the acs-kernel libraries may not have
# been loaded (which is fine, since index.tcl will display a message
# instructing the user to install the Oracle driver and restart the server
# before proceeding any further; in this case we won't use any procedures
# depending on the core libraries). Otherwise, all -procs.tcl files in
# acs-kernel (but not any -init.tcl files) will have been run.

# Return a header for an installation page, suitable for ns_writing.
# This procedure engages the installer mutex, as every installer page is a critical section.

proc install_header { status title } {
    return "HTTP/1.0 $status OK
MIME-Version: 1.0
Content-Type: text/html

<html>
  <head>
    <title>OpenACS Installation: $title</title>
  </head>
  <body bgcolor=white>
    <h2>OpenACS Installation: $title</h2>
    <hr>
"
}

# Return a footer for an installation page, suitable for ns_writing.
# This procedure must be called at the end of every installer page to end the critical section.
proc install_footer {} {
    return "<hr>
<a href=\"mailto:gatekeepers@openacs.org\"><address>gatekeepers@openacs.org</address></a>

  </body>
</html>
"
}

# Write headers and a whole page.
proc install_return { status title page } {
    ns_write "[install_header $status $title]
$page
[install_footer]"
}

# Write out a bullet item (suitable for use as a callback for, e.g., apm_register_new_packages).
proc install_write_bullet_item { item } {
    ns_write "$item<li>\n"
}

# Does the ACS kernel data model seem installed?
proc install_good_data_model_p {} {
    foreach table_name { acs_objects sec_session_properties } {
	if { ![db_table_exists $table_name] } {
	    return 0
	}
    }
    return 1
}

# Returns a simple next button.
proc install_next_button { url } {
    return "<form action=$url method=get><center><input type=submit value=\"Next ->\"></center>"
}


proc install_file_serve { path } {
    if {[file isdirectory $path] && [string index [ad_conn url] end] != "/" } {
  	ad_returnredirect "[ad_conn url]/"
    } else {
	ns_log Debug "Installer serving $path"
	ad_try {
	    rp_serve_abstract_file $path
	} notfound val {
	    install_return 404 "Not found" "
	    The file you've requested, doesn't exist. Please check
	    your URL and try again."
	} redirect url {
	    ad_returnredirect $url
	} directory dir_index {
	    set new_file [file join $path "index.html"]
	    if {[file exists $new_file]} {
		rp_serve_abstract_file $new_file
	    } 
	    set new_file [file join $path "index.adp"]
	    if {[file exists $new_file]} {
		rp_serve_abstract_file $new_file
	    } 
	}
    }
}

# The preauth filter which serves installation scripts.
proc install_handler { conn arg why } {
    # Redirect requests to /doc appropriately.  Thus, the installer can reference the install guide.
    if { [regexp {/doc(.*)} [ad_conn url] "" doc_url] } {
	set doc_urlv [split [string trimleft $doc_url] /]
	set package_key [lindex $doc_urlv 1]
	ns_log Debug "Scanning $doc_url with package_key $package_key..."
	if {[file isfile "[acs_root_dir]/packages/acs-core-docs/www[join $doc_urlv /]"]} {
	    install_file_serve "[acs_root_dir]/packages/acs-core-docs/www[join $doc_urlv /]"
	} elseif {[file isdirectory \
		"[acs_root_dir]/packages/acs-core-docs/www[join $doc_urlv /]"]} {
	    install_file_serve "[acs_root_dir]/packages/acs-core-docs/www[join $doc_urlv /]"
	} elseif {[file isdirectory "[acs_root_dir]/packages/$package_key/www/doc"]} {
	    install_file_serve "[acs_root_dir]/packages/$package_key/www/doc[join [lrange $doc_urlv 2 end] /]"
	} else {
	    install_file_serve "[acs_root_dir]/packages/$package_key/doc[join $doc_url /]"
	}
	return "filter_return"
    }

    # Make sure any requests to /SYSTEM still get through.  This is useful if your server
    # is setting behind a load balancer that uses SYSTEM pages to verify that the server
    # is still working.
    if { [regexp {/SYSTEM/(.*)} [ad_conn url] "" system_file] } {
	if {[string compare [string range $system_file \
		[expr [string length $system_file ] - 4] end] ".tcl"
	]} {
	    set system_file "$system_file.tcl"
	}
	apm_source "[acs_root_dir]/www/SYSTEM/$system_file"
	return "filter_return"
    }

    if { ![regexp {/([a-zA-Z0-9\-_]*)$} [ad_conn url] "" script] } {
	ad_returnredirect "/"
	return
    }

    if { ![string compare $script ""] } {
	set script "index"
    }

    set path "[nsv_get acs_properties root_directory]/packages/acs-bootstrap-installer/installer/$script.tcl"
    if { ![info exists path] } {
	install_return 404 "Not found" "
The installation script you've requested, <code>$script</code>, doesn't exist. Please check
your URL and try again.
"
    }
    # Engage a mutex for double-click protection.
    ns_mutex lock [nsv_get acs_installer mutex]
    if { [catch {
	# Source the page and then unlock the mutex.
	apm_source $path
	ns_mutex unlock [nsv_get acs_installer mutex]
    } error] } {
	# In case of an error, don't forget to unlock the mutex.
	ns_mutex unlock [nsv_get acs_installer mutex]
	global errorInfo
	install_return 500 "Error" "The following error occurred in an installation script:

<blockquote><pre>[ns_quotehtml $errorInfo]</pre></blockquote>
"

    }
    return "filter_return"
}

proc install_admin_widget {} {

    return "
	<form action=create-administrator>
	<input type=hidden name=done_p value=1>
	<center>
	<input type=submit value=\"Create Administrator ->\">
	</center>
"

}

proc install_redefine_ad_conn {} {

    # Peter Marklund
    # We need to be able to invoke ad_conn in the installer. However
    # We cannot use the rp_filter that sets up ad_conn
    proc ad_conn {attribute} {
        if { [string equal $attribute "-connected_p"] } {
            set return_value 1
        } elseif { [catch {set return_value [ns_conn $attribute] } error] } {
            set return_value ""
        }

        return $return_value
    }
}

ad_proc -public ad_windows_p {} {
    # DLB - this used to check the existence of the WINDIR environment
    # variable, rather than just asking AOLserver.
    Returns 1 if the ACS is running under Windows.
    Note,  this procedure is a best guess, not sure of a better way of determining:
} {
    set thisplatform [ns_info platform]
    if {[string equal $thisplatform  "win32" ]} {
       return 1
    } else {
       return 0
    }
}


# Register the install handler.
ns_register_filter preauth GET * install_handler
ns_register_filter preauth POST * install_handler
ns_register_filter preauth HEAD * install_handler
