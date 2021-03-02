ad_library {

    Functions that the content-repository uses to interact with the
    filesystem.

    @author Dan Wickstrom (dcwickstrom@earthlink.net)
    @creation-date Sat May  5 13:45 2001
    @cvs-id $Id$
}

# The location for files
ad_proc -private cr_fs_path { { location CR_FILES } } {

    Root path of content repository files.

} {
    return [nsv_get CR_LOCATIONS $location]
}

ad_proc -public cr_create_content_file_path {item_id revision_id} {

    Creates a unique file in the content repository filesystem based on
    the item_id and revision_id of the content item.

} {

    # Split out the version_id by groups of 2.
    set item_id_length [string length $item_id]
    set path "/"

    for {set i 0} {$i < $item_id_length} {incr i} {
        append path [string range $item_id $i $i]
        if {($i % 2) == 1} {
            if {$i < $item_id_length} {
                # Check that the directory exists
                if {![file exists [cr_fs_path]$path]} {
                    file mkdir [cr_fs_path]$path
                }

                append path "/"
            }
        }
    }

    # Check that the directory exists
    if {![file exists [cr_fs_path]$path]} {
        file mkdir [cr_fs_path]$path
    }

    if {[string index $path end] ne "/" } {
        append path "/"
    }

    return "${path}${revision_id}"
}

# lifted from new-file-storage (DanW - OpenACS)

ad_proc -public cr_create_content_file {
    -move:boolean
    item_id
    revision_id
    client_filename
} {
    Copies the file passed by client_filename to the content repository file
    storage area, and it returns the relative file path from the root of the
    content repository file storage area..

    if the -move flag is given the file is renamed instead
} {
    set content_file [cr_create_content_file_path $item_id $revision_id]
    set dir [cr_fs_path]

    if { $move_p } {
        file rename -- $client_filename $dir$content_file
    } else {
        file copy -force -- $client_filename $dir$content_file
    }

    cr_add_to_file_creation_log $content_file

    return $content_file
}

ad_proc -public cr_create_content_file_from_string {item_id revision_id str} {

    Copies the string to the content repository file storage area, and it
    returns the relative file path from the root of the content repository
    file storage area.

} {
    ad_mutex_eval [nsv_get mutex cr_file_creation] {
        set content_file [cr_create_content_file_path $item_id $revision_id]
        set ofp [open [cr_fs_path]$content_file w]
        puts -nonewline $ofp $str
        close $ofp
    }
    cr_add_to_file_creation_log $content_file
    return $content_file
}

ad_proc -public cr_file_size {relative_file_path} {

    Returns the size of a file stored in the content repository.  Takes the
    relative file path of the content repository file as an argument.

} {
    return [file size [cr_fs_path]$relative_file_path]
}


#
# Manage a log for created files in the content repository. The log is
# used for cleaning up orphaned files after aborted transactions
# involving file inserts in the content repository.
#

ad_proc -private cr_add_to_file_creation_log {content_file} {

    Record an entry in the file creation log for managing orphaned
    files.

} {
    set dir [cr_fs_path]
    ad_mutex_eval [nsv_get mutex cr_file_creation] {
        set f [open $dir/file-creation.log a]
        puts $f $content_file
        close $f
    }
}

ad_proc -private cr_get_file_creation_log {} {

    Return the contents of the file creation log and truncate it
    (i.e. remove all entries).

} {
    set dir [cr_fs_path]
    set logName $dir/file-creation.log
    ad_mutex_eval [nsv_get mutex cr_file_creation] {
        if {[file readable $logName]} {
            set f [open $logName]
            set content [read $f]
            close $f
            # truncate the log file
            set f [open $logName w]; close $f
        } else {
            set content ""
        }
    }
    return $content
}

ad_proc -private cr_check_file_entry {name} {

    Check if an entriy from the content repository having the
    specified partial path their content field exists.

    @result boolean success

} {
    db_0or1orw check_entry {
        SELECT 1 FROM cr_revisions
        WHERE substring(content, 1, 100) = substring(:name, 1, 100)
    }
}

ad_proc -private cr_count_file_entries {name} {

    Count entries an entries from the content repository having the
    specified partial path their content field.

    @result integer count

} {
    db_string count_entries {
        SELECT count(*) FROM cr_revisions
        WHERE substring(content, 1, 100) = substring(:name, 1, 100)
    }
}


ad_proc -private cr_delete_orphans {files} {

    Delete orphaned files in the content repository.

} {
    set dir [cr_fs_path]
    foreach name $files {

        if {![file exists $dir$name]} {
            # the file does not exist anymore, nothing to do
            continue
        }

        if {![regexp {^[0-9/]+$} $name]} {
            ns_log notice "orphan handling: ignore strange entry from deletion log <$dir$name>"
            continue
        }

        set count [cr_count_file_entries $name]
        if {$count == 0} {
            # the content entry does not exist anymore, therefore, the
            # file is an orphan and should be removed
            ns_log notice "delete orphaned file $dir$name"
            file delete -- $dir$name
        }
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
