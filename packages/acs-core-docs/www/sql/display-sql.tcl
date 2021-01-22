ad_page_contract {
    Enables user to see a .sql file without encountering the 
    AOLserver's db module magic (offering to load the SQL into a database)
    or without returning the SQL as content-type application/x-sql.

    Patched by philg at Jeff Davis's request on 12/5/99
    to close the security hole whereby a client adds extra form
    vars.

    Patched on 07/06/2000 by deison to restrict access to only
    .sql files and only files in /doc or /pageroot.

    2000 August 8 Updated for ACS4 packages - richardl@arsdigita.com.

    @param url The full relative path of the file to display the source for.
    @param package_key The key of the package the file is part of.

    @author philg@mit.edu
    @creation-date 12/19/98
    @cvs-id $Id$
} {
    url:notnull
    {package_key:token ""}
    {db:word ""}
}

# This is normally a password-protected page, but to be safe let's
# check the incoming URL for ".." to make sure that someone isn't
# doing
# https://photo.net/doc/sql/display-sql.tcl?url=/../../../../etc/passwd
# for example

if { [string match "*..*" $url] || [string match "*..*" $package_key] } {
    ad_return_warning "Can't back up beyond the pageroot" "You can't use display-sql.tcl to look at files underneath the pageroot."
    ad_script_abort
}


if {$db eq ""} { 

    # if we were not passed a DB string get a list of matching files.

    set text {<ul>}
    set files [glob -nocomplain "[acs_package_root_dir $package_key]/sql/*/$url" "[acs_package_root_dir $package_key]/sql/$url"]
    foreach f $files { 
        regexp {([^/]*)/([^/]*)$} $f match db url
        append text [subst {
	    <li> <a href="[ns_quotehtml [export_vars -base display-sql {db url package_key}]]">$db</a></li>
	}]
    }
    if {$files eq ""} { 
        append text "<li> No sql file found."
    }
    append text {</ul>}
    set context [list [list ../$package_key $package_key] "SQL Display"]

} else { 

    # we have a db.  


    if {$db eq "sql"} { 
        set files [glob -nocomplain "[acs_package_root_dir $package_key]/sql/$url"]       
    } else { 
        set files [glob -nocomplain "[acs_package_root_dir $package_key]/sql/$db/$url"]       
    }

    if {$package_key ne ""} {
        set safe_p [regexp {/?(.*)} $url package_url]
    } else {
        set safe_p 0
    }

    if { $safe_p && [llength $files] > 0 } {
        ns_returnfile 200 text/plain $files
    } else {
        ad_return_warning "Invalid file location" "Can only display files in package or doc directory."
    }
    ad_script_abort
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
