ad_page_contract {
    Loads a package from a URL or local filesystem into the package manager.

    @param source URL (http/https, including GitHub) or absolute local path.
    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Gustaf Neumann (neumann@wu-wien.ac.at)
    @creation-date 10 October 2000
} {
    {source ""}
    {delete:boolean,notnull 0}
} -validate {

    source_present {
        if {$source eq ""} {
            ad_complain
        }
    }

    source_absolute_path_or_url {
        # Accept http(s) URLs, otherwise require absolute path
        if {![regexp {^https?://} $source] && ![string match "/*" $source]} {
            ad_complain
        }
    }

} -errors {
    source_present {You must specify a package source (URL or absolute local path).}
    source_absolute_path_or_url {Local paths must be absolute (start with “/”), or provide an http(s) URL.}
}

if {$delete} {
    file delete -force -- [apm_workspace_install_dir]
}

set title "Contents of Loaded Package"
set context [list [list "." "Package Manager"] [list "package-load" "Load a New Package"] $title]

ad_return_top_of_page [ad_parse_template \
                           -params [list context title] \
                           [template::streaming_template]]

ns_write "<ul>\n"

set is_url_p [regexp {^https?://} $source]

if {$is_url_p} {
    ns_write "<li>Downloading $source...\n"
    ns_log Debug "APM: Loading from url $source"

    # URL install: pass -url and keep file_path empty
    apm_load_apm_file -url $source -callback apm_ns_write_callback ""

} else {
    set file_path $source
    ns_write "<li>Accessing $file_path...\n"
    ns_log Debug "APM: Loading $file_path"

    # Local install: single .apm file?
    if {[file extension $file_path] eq ".apm"} {
        apm_load_apm_file -callback apm_ns_write_callback $file_path

    } elseif {[file isdirectory $file_path]} {
        # Directory: load all .apm files
        set apm_file_list [glob -nocomplain "$file_path/*.apm"]
        if {$apm_file_list eq ""} {
            ns_write [subst {
                <li>The directory specified, <code>$file_path</code>, does not contain any APM files.
                Please <a href="package-load">try again</a>.
            }]
            ns_write "</ul>\n"
            return
        }

        foreach apm_file $apm_file_list {
            ns_write "<li>Loading $apm_file... <ul>\n"
            apm_load_apm_file -callback apm_ns_write_callback $apm_file
            ns_write "<li>Done.</ul>\n"
        }

    } else {
        ns_write [subst {
            <li>The specified path <code>$file_path</code> is not an APM file and not a directory.
            Please <a href="package-load">try again</a>.
        }]
        ns_write "</ul>\n"
        return
    }
}

ns_write [subst {
</ul>
The package(s) are now extracted into your filesystem. You can <a href="package-load">load another new package</a>
or proceed to <a href="packages-install">install</a> the package(s).
}]
