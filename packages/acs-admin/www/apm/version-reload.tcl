ad_page_contract { 
    Marks all changed -procs.tcl files in a version for reloading.

    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:naturalnum,notnull}
    {return_url:localurl "index"}
}

apm_version_info $version_id

set title "Reload $pretty_name"
set context [list \
                 [list "../developer" "Developer's Administration"] \
                 [list "/acs-admin/apm/" "Package Manager"] \
                 [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] \
                 $title]

#
# Mark files in this package for reloading and return the list.
#
set files [apm_mark_version_for_reload $version_id]

set files_to_watch [list]

if { [llength $files] == 0 } {
    append body "There are no changed files to reload in this package.<p>"
} else {
    append body "Marked the following file[ad_decode [llength $files] 1 "" "s"] for reloading:<ul id='files'>\n"

    #
    # Source all of the marked files using the current interpreter,
    # accumulating errors in the provided variable
    #
    array set errors [list]
    ad_try {
        apm_load_any_changed_libraries -version_files $files errors

    } on error {errorMsg} {
        ns_log notice "version-reload: apm_load_any_changed_libraries lead to $errorMsg"
        set errHTML "<p>Error during apm_load_any_changed_libraries:</p><pre>[ns_quotehtml $errorMsg]</pre>"

    } on ok {r} {
        set errHTML ""
    }

    ns_log notice "version-reload: apm_load_any_changed_libraries reports [array size errors] errors"
    
    if {[array size errors] > 0 || $errHTML ne ""} {
        #
        # When something went wrong during loading, we might have
        # messed up already the blueprint for the current
        # interpreter. So make sure, this interpreter is not used
        # anymore.
        #
        if {[ns_info name] eq "NaviServer"} {
            ns_ictl markfordelete
        } else {
            ns_markfordelete
        }
    }
    
    if {[info exists errors($package_key)]} {
        array set package_errors $errors($package_key)
    } else {
        array set package_errors [list]
    }

    foreach file $files {
        append body "<li>$file"
        if { [nsv_exists apm_reload_watch $file] } {
            append body " (currently being watched)"
        } else {
            # This file isn't being watched right now - provide a link setting a watch on it.
            set files_to_watch_p 1

            # Remove the two first elements of the path, namely packages/package-key/
            set local_path [file join {*}[lrange [file split $file] 2 end]]
            set href [export_vars -base file-watch { version_id { paths $local_path } }]
            append body [subst {
                (<a href="[ns_quotehtml $href]">watch this file</a>)
            }]
            lappend files_to_watch $local_path
        }

        if {[info exists package_errors($file)]} {
            append body "<dl class='error'><dt title='Errors while loading $file'>ERROR!</dt>" \
                "<dd><code><pre>[ns_quotehtml $package_errors($file)]</pre></code></dd></dl>"
        }
        append body "</li>\n"
    }
    append body "</ul>\n"

    set n_errors [array size package_errors]
    if {$n_errors > 0} {
        if {$n_errors > 1} {
            set exist_n_error_files "were $n_errors files"
        } else {
            set exist_n_error_files "was $n_errors file"
        }
        append body "
        <p><strong style='color:red;font-size:112.5%;'>There
        $exist_n_error_files with errors that prevented complete
        reloading</strong>.  Fix the problem, then reload the
        package again to finish the reload.
        </p>
    "
    }
    append body $errHTML
}


if { [info exists files_to_watch_p] } {
    set href [export_vars -base file-watch { version_id { paths:multiple $files_to_watch } }]
    append body [subst {
        If you know you're going to be modifying one of the above files frequently,
        select the "watch this file" link next to a filename to cause the interpreters to
        reload the file immediately whenever it is changed.<p>
        <ul class="action-links">
        <li><a href="[ns_quotehtml $href]">Watch all above files</a></li>
    }]
} else {
    append body "<ul class=\"action-links\">"
}

append body [subst {
    <li><a href="$return_url">Return</a></li>
    </ul>
}]

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
