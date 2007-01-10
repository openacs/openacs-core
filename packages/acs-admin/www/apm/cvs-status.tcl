ad_page_contract {
    Tells the user what he needs to do to ensure that all packages
    he owns are checked into CVS.
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$
} {
}

db_1row email_by_user_id {}

doc_body_append "[apm_header "Your Non-Up-To-Date Files"]"

set last_version -1

set no_changes [list]

set all_files_to_add [list]
set all_files_to_commit [list]

db_foreach all_packages_owned_by_email "
    select v.package_key, v.version_id, v.package_name, v.version_name
    from   apm_package_version_info v, apm_package_owners o
    where  o.owner_url = :email
    and    v.version_id = o.version_id
    and    v.installed_p = 't'
    order by upper(package_name)" {
    
	set files_to_add [list]
	set files_to_commit [list]

	# Determine which files in this package are not considered up-to-date by CVS.
	set counter 0
	db_foreach apm_file_path {
	    select path from apm_package_files where version_id = :version_id
	}{
	    vc_parse_cvs_status [apm_fetch_cached_vc_status "packages/$package_key/$path"]
	    global vc_file_props
	    if { [regexp {[a-zA-Z]} $vc_file_props(status)] } {
		set status "$vc_file_props(status)"
		if { $status eq "Up-to-date" } {
		    # It's up to date; don't print anything out.
		    continue
		}
	    } else {
		# CVS hasn't ever heard of it! It probably needs to be added to the
		# repository.
		set status "Unknown"
		lappend files_to_add "packages/$package_key/$path"
	    }
	    if { $counter == 0 } {
		# This is the first item we're printing out; display the package name too.
		doc_body_append "<h3>$package_name $version_name (<code>packages/$package_key</code>)</h3><ul>\n"
	    }
	    lappend files_to_commit "packages/$package_key/$path"
	    doc_body_append "<li>$path: <b>$status</b>"
	    
	    # Try writing the name of the user who owns the file. Don't sweat it if we can't.
	    catch { doc_body_append " (owned by [file attributes "[acs_root_dir]/$path" -owner])" }
	    
	    doc_body_flush
	    incr counter
	}
	if { $counter == 0 } {
	    # No changes at all to this package.
	    lappend no_changes "$package_name $version_name"
	} else {
	    # Tell the user how to bring everything up to date.
	    doc_body_append "</ul>To commit these changes:<blockquote><pre>cd [acs_root_dir]\n"
	if { [llength $files_to_add] > 0 } {
	    doc_body_append [apm_shell_wrap [concat [list cvs add] $files_to_add]]
	}
	    doc_body_append [apm_shell_wrap [concat [list cvs commit] $files_to_commit]]
	    doc_body_append "</pre></blockquote>"
	}
	doc_body_flush
	
	set all_files_to_add [concat $all_files_to_add $files_to_add]
	set all_files_to_commit [concat $all_files_to_commit $files_to_commit]
    }

if { [llength $no_changes] > 0 } {
    doc_body_append "<h3>No changes to:</h3><ul><li>[join $no_changes "\n<li>"]</ul>\n"
}

if { [llength $all_files_to_commit] > 0 } {
    doc_body_append "<h3>To commit all changes:</h3><blockquote><pre>cd [acs_root_dir]\n"
    if { [llength $all_files_to_add] > 0 } {
	doc_body_append [apm_shell_wrap [concat [list cvs add] $all_files_to_add]]
    }
    doc_body_append [apm_shell_wrap [concat [list cvs commit] $all_files_to_commit]]
    doc_body_append "</pre></blockquote>"
}

doc_body_append "<a href=\"./\">Return to the Package Manager</a>

[ad_footer]"

    