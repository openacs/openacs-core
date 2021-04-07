ad_library {

    CRUD procedures for content revisions

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-04
    @cvs-id $Id$
}

namespace eval ::content::revision {}

ad_proc -public ::content::revision::new {
    {-revision_id ""}
    {-item_id:required}
    {-title ""}
    {-description ""}
    {-content ""}
    {-mime_type ""}
    {-publish_date ""}
    {-nls_language ""}
    {-creation_date ""}
    {-content_type}
    {-creation_user}
    {-creation_ip}
    {-package_id}
    {-attributes}
    {-is_live "f"}
    {-tmp_filename ""}
    {-storage_type ""}
} {
    Adds a new revision of a content item. If content_type is not
    passed in, we determine it from the content item. This is needed
    to find the attributes for the content type.


    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-04

    @param revision_id

    @param item_id

    @param content_type

    @param title

    @param description

    @param content

    @param mime_type

    @param publish_date

    @param nls_language

    @param creation_date

    @param creation_user

    @param creation_ip

    @param package_id Package_id content belongs to

    @param is_live True is revision should be set live

    @param tmp_filename file containing content to be added to revision.
           The caller is responsible for cleaning up the temporary file.

    @param package_id

    @param is_live

    @param attributes A list of lists of pairs of additional attributes and
    their values to pass to the constructor. Each pair is a list of two
     elements: key => value such as
    [list [list attribute value] [list attribute value]]

    @return

    @error
} {

    if {![info exists creation_user]} {
        set creation_user [ad_conn user_id]
    }

    if {![info exists creation_ip]} {
        set creation_ip [ad_conn peeraddr]
    }

    if {![info exists content_type] || $content_type eq ""} {
        set content_type [::content::item::get_content_type -item_id $item_id]
    }
    if {$storage_type eq ""} {
        set storage_type [db_string get_storage_type ""]
    }
    if {![info exists package_id]} {
        set package_id [ad_conn package_id]
    }
    set attribute_names ""
    set attribute_values ""

    if { [info exists attributes] && $attributes ne "" } {
        set type_attributes [package_object_attribute_list $content_type]
        set valid_attributes [list]
        # add in extended attributes for this type, ignore
        # content_revision as those are already captured as named
        # parameters to this procedure

        foreach type_attribute $type_attributes {
            if {"cr_revisions" ne [lindex $type_attribute 1]
                && "acs_objects" ne [lindex $type_attribute 1]
            } {
                lappend valid_attributes [lindex $type_attribute 2]
            }
        }
        foreach attribute_pair $attributes {
            lassign $attribute_pair attribute_name attribute_value
            if {$attribute_name in $valid_attributes}  {

            # first add the column name to the list
            append attribute_names  ", ${attribute_name}"
                # create local variable to use for binding
                set $attribute_name $attribute_value
                append attribute_values ", :${attribute_name}"
            }
        }
    }

    set table_name [acs_object_type::get_table_name -object_type $content_type]
    set mime_type [cr_check_mime_type \
                       -filename  $title \
                       -mime_type $mime_type \
                       -file      $tmp_filename]

    set query_text [subst {
        insert into ${table_name}i
        (revision_id, object_type, creation_user, creation_date, creation_ip, title, description, item_id, object_package_id, mime_type $attribute_names)
        values (:revision_id, :content_type, :creation_user, :creation_date, :creation_ip, :title, :description, :item_id, :package_id, :mime_type $attribute_values)
    }]

    db_transaction {
        # An explicit lock was necessary for PostgreSQL between 8.0 and
        # 8.2; left the following statement here for documentary purposes
        #
        # db_dml lock_objects "LOCK TABLE acs_objects IN SHARE ROW EXCLUSIVE MODE"

        if {$revision_id eq ""} {
            set revision_id [db_nextval "acs_object_id_seq"]
        }
        # the postgres "insert into view" is rewritten by the rule into a "select"
        [expr {[db_driverkey ""] eq "postgresql" ? "db_0or1row" : "db_dml"}] \
            insert_revision $query_text

        ::content::revision::update_content \
            -item_id $item_id \
            -revision_id $revision_id \
            -content $content \
            -tmp_filename $tmp_filename \
            -storage_type $storage_type \
            -mime_type $mime_type
    }
    if {[string is true $is_live]} {
        content::item::set_live_revision -revision_id $revision_id
    }
    return $revision_id
}

#
# ::content::revision::collect_cleanup_data
#

ad_proc -private ::content::revision::collect_cleanup_data {
    -item_id:required
    -storage_type:required
} {
    return [::content::revision::collect_cleanup_data-$storage_type -item_id $item_id]
}

ad_proc -private ::content::revision::collect_cleanup_data-text {
    -item_id:required
} {
    return
}

ad_proc -private ::content::revision::collect_cleanup_data-lob {
    -item_id:required
} {
    return
}

ad_proc -private ::content::revision::collect_cleanup_data-file {
    -item_id:required
} {
    return [db_list get_files {select content from cr_revisions where item_id = :item_id}]
}

#
# ::content::revision::cleanup
#
ad_proc -private ::content::revision::cleanup {
    -storage_type:required
    -storage_area_key:required
    -data:required
} {
    return [::content::revision::cleanup-$storage_type \
                -storage_area_key $storage_area_key \
                -data $data]
}

ad_proc -private ::content::revision::cleanup-text {
    -storage_area_key:required
    -data:required
} {
    return
}

ad_proc -private ::content::revision::cleanup-lob {
    -storage_area_key:required
    -data:required
} {
    return
}

ad_proc -private ::content::revision::cleanup-file {
    -storage_area_key:required
    -data:required
} {

    This function cleans-up files AFTER the DB-entry was deleted.  If
    the transaction is aborted, the file will not be executed and the
    file will survive. Thus function should make
    cr_check_orphaned_files obsolete, which does not scale.

    @see cr_check_orphaned_files
} {
    set dir [cr_fs_path $storage_area_key]
    foreach filename $data {
        ns_log notice "DELETE FILE $dir$filename"
        file delete $dir$filename
    }
}


ad_proc -private ::content::revision::check_files {
    {-max_results 5000}
    {-max_checks 10000}
    {-returnlist:boolean}
} {
    Figure out, how many files in the CR are not linked to the
    revisions in the content repository, and report them
    optionally.

    @author Gustaf Neumann

    @param max_results stop after having found so many non-referenced files
    @param max_checks stop after having checked so many non-referenced files
    @param returnlist return the non-referenced files as part of the result
} {
    set paths [cr_fs_path CR_FILES]
    set prefix_length [string length $paths]
    set count 1
    set missing 0
    set files {}
    while {[llength $paths] > 0} {
        # get the first path
        set paths [lassign $paths path]
        #ns_log notice "popping path '$path' form paths, remaining [llength $paths]"

        set children [glob -nocomplain -directory $path *]
        foreach child $children {
            if {[file tail $child] in {. ..}} {
                continue
            }
            if {[file isdirectory $child]} {
                #
                # Using "lappend" leads to a breadth-search: might be
                # slow when the directories a huge, since it takes a
                # while until leaves are found.
                #
                #lappend paths $child

                set paths [lreplace $paths -1 -2 $child]
                #ns_log notice "child is dir $child"
            } else {
                set suffix [string range $child $prefix_length end]
                set success [cr_count_file_entries $suffix]
                if {$success == 0} {
                    ns_log notice "check_files: $count file $child not in db entries"
                    incr missing
                    lappend files $child
                }
                incr count
                if {$count >= $max_checks || $missing >= $max_results} break

            }
        }
        if {$count >= $max_checks || $missing >= $max_results} break
    }
    set msg "$missing of $count files are not ok (not contained in db entries)"
    if {$returnlist_p} {
        append msg \n [join $files \n]
    }
    return $msg
}

ad_proc -private ::content::revision::check_dirs {
    {-max_results 5000}
    {-max_checks 10000}
    {-returnlist:boolean}
    {-prune:boolean}
} {
    Figure out, how many directories in the CR are empty, report them
    optionally or delete them optionally.

    @author Gustaf Neumann

    @param max_results stop after having found so many empty directories
    @param max_checks stop after having checked so many directories
    @param prune delete the found empty directories
    @param returnlist return the directories as part of the result
} {
    set paths [cr_fs_path CR_FILES]
    set prefix_length [string length $paths]
    set count 1
    set empty_dirs 0
    set dirs 0
    set empty_dir_list {}
    while {[llength $paths] > 0} {
        # get the first path
        set paths [lassign $paths path]
        #ns_log notice "popping path '$path' form paths, remaining [llength $paths]"

        set children [glob -nocomplain -directory $path *]
        set nr_children 0
        incr dirs
        foreach child $children {
            if {[file tail $child] in {. ..}} {
                continue
            }
            if {[file isdirectory $child]} {
                #
                # Using "lappend" leads to a breadth-search: might be
                # slow when the directories a huge, since it takes a
                # while until leaves are found.
                #
                #lappend paths $child

                set paths [lreplace $paths -1 -2 $child]
                #ns_log notice "child is dir $child"
            }
            incr nr_children
        }
        if {$nr_children == 0} {
            incr empty_dirs
            ns_log notice "check_dirs: directory $path is empty ($empty_dirs out of $dirs)"
            lappend empty_dir_list $path
            if {$prune_p && [regexp {^\d+$} [file tail $path]]} {
                file delete $path
            }
        }
        if {$empty_dirs >= $max_results || $dirs >= $max_checks} {
            break
        }
    }
    set msg "$empty_dirs out of $dirs directories are empty"
    ns_log notice "check_dirs: $msg"
    if {$returnlist_p} {
        append msg \n [join $empty_dir_list \n]
    }
    return $msg
}

ad_proc -private ::content::revision::file_stats {
    {-max 10000}
} {

    Determine some basic statistics about files in the CR based on a
    sample. This is useful for large installations with several
    million of files, where a detailed analysis would take very long.

    @author Gustaf Neumann

    @param max number of revisions with storage-type "file" to check
    @result some statistics
} {
    set tuples [db_list_of_lists get_file_names {
        select i.item_id, revision_id, mime_type, content_length
        from cr_items i, cr_revisions r
        where storage_type = 'file'
        and storage_area_key = 'CR_FILES'
        and  r.item_id = i.item_id
        FETCH FIRST :max ROWS ONLY
    }]
    set count 0
    set total_length 0
    set empty_files 0
    foreach tuple $tuples {
        lassign $tuple item_id revision_id mime_type content_length
        incr count
        if {$content_length eq ""} {
            ns_log warning "file_stats: entry has no content_length: revision_id $revision_id mime_type $mime_type"
        } else {
            incr total_length $content_length
        }
        incr mime_types($mime_type)
        incr revisions_for_item($item_id)
        if {$content_length < 1} {
            incr empty_files
        }
    }
    set result ""
    if {$count > 0} {
        set backup_files 0
        set files_with_multiple_revisions 0
        foreach {item_id revs} [array get revisions_for_item] {
            if {$revs > 1} {
                incr files_with_multiple_revisions
                incr backup_files [expr {$revs - 1}]
            }
        }
        set most_common [lrange [lsort \
                                     -integer \
                                     -stride 2 \
                                     -index 1 \
                                     -decreasing \
                                     [array get mime_types]
                                ] 0 11]

        append result \
            "checked files                : $count\n" \
            "files with multiple revisions: $files_with_multiple_revisions\n" \
            "backup files                 : $backup_files\n" \
            "empty files                  : $empty_files\n" \
            "avg file size                : [format %10.2f [expr {$total_length*1.0/$count}]]\n" \
            "mime_types: $most_common"
        ns_log notice "file_stats: $result"
    }
    return $result
}




#
# ::content::revision::update_content
#
ad_proc -private ::content::revision::update_content {
    -item_id:required
    -revision_id:required
    -content:required
    -storage_type:required
    -mime_type:required
    {-tmp_filename ""}
} {

    Update content column separately. Oracle does not allow insert
    into a BLOB.

    This assumes that if storage type is lob and no file is specified
    that the content is really text and store it in the text column
    in PostgreSQL

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-02-09

    @param revision_id Content revision to update

    @param content Content to add to resivsion
    @param storage_type text, file, or lob
    @param mime_type mime type of the content
    @param tmp_filename For storage types except 'text'
           a filename can be specified
           instead of 'content'. The caller is responsible
           for cleaning up the temporary file
} {
    ns_log notice "============== update_content-$storage_type $revision_id content '$content' mime_type $mime_type tmp_filename '$tmp_filename'"
    ::content::revision::update_content-$storage_type \
        -item_id $item_id \
        -revision_id $revision_id \
        -content $content \
        -mime_type $mime_type \
        -tmp_filename $tmp_filename
}

ad_proc -private ::content::revision::update_content-text {
    -item_id:required
    -revision_id:required
    -content:required
    -mime_type:required
    {-tmp_filename ""}
} {
    db_dml update_content "" -blobs [list $content]

    if {$tmp_filename ne ""} {
        # Traditionally, a provided tmp_file is not handled. I
        # could/should be probably supported in the future.
        ns_log warning "::content::revision::update_content-text: provided tmp_filename is ignored"
    }
}

ad_proc -private ::content::revision::update_content-file {
    -item_id:required
    -revision_id:required
    -content:required
    -mime_type:required
    {-tmp_filename ""}
} {
    if {$tmp_filename eq ""} {
        set filename [cr_create_content_file_from_string $item_id $revision_id $content]
    } else {
        set filename [cr_create_content_file $item_id $revision_id $tmp_filename]
    }
    set tmp_size [file size [cr_fs_path]$filename]
    db_dml set_file_content {
        update cr_revisions
        set content = :filename,
            mime_type = :mime_type,
            content_length = :tmp_size
        where revision_id = :revision_id
    }
}

ad_proc -private ::content::revision::update_content-lob {
    -item_id:required
    -revision_id:required
    -content:required
    -mime_type:required
    {-tmp_filename ""}
} {
    if {$tmp_filename ne ""} {
        # handle file
        set filename [cr_create_content_file $item_id $revision_id $tmp_filename]
        db_dml set_content "" -blob_files [list $tmp_filename]
        db_dml set_size ""
    } else {
        # handle blob
        db_dml update_content "" -blobs [list $content]
    }
}


ad_proc -public content::revision::content_copy {
    -revision_id:required
    {-revision_id_dest ""}
} {
    @param revision_id
    @param revision_id_dest
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
        [list revision_id_dest $revision_id_dest ] \
    ] content_revision content_copy]
}


ad_proc -public content::revision::copy {
    -revision_id:required
    {-copy_id ""}
    {-target_item_id ""}
    {-creation_user ""}
    {-creation_ip ""}
} {
    @param revision_id
    @param copy_id
    @param target_item_id
    @param creation_user
    @param creation_ip

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
        [list copy_id $copy_id ] \
        [list target_item_id $target_item_id ] \
        [list creation_user $creation_user ] \
        [list creation_ip $creation_ip ] \
    ] content_revision copy]
}


ad_proc -public content::revision::delete {
    -revision_id:required
} {
    @param revision_id
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision del]
}


ad_proc -public content::revision::export_xml {
    -revision_id:required
} {
    @param revision_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision export_xml]
}


ad_proc -public content::revision::get_number {
    -revision_id:required
} {
    @param revision_id

    @return NUMBER
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision get_number]
}


ad_proc -public content::revision::import_xml {
    -item_id:required
    -revision_id:required
    -doc_id:required
} {
    @param item_id
    @param revision_id
    @param doc_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list revision_id $revision_id ] \
        [list doc_id $doc_id ] \
    ] content_revision import_xml]
}


ad_proc -public content::revision::index_attributes {
    -revision_id:required
} {
    @param revision_id
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision index_attributes]
}


ad_proc -public content::revision::is_latest {
    -revision_id:required
} {
    @param revision_id

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision is_latest]
}


ad_proc -public content::revision::is_live {
    -revision_id:required
} {
    @param revision_id

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision is_live]
}


ad_proc -public content::revision::item_id {
    -revision_id:required
} {
  Gets the item_id of the item to which the revision belongs.

  @param  revision_id   The revision id

  @return The item_id of the item to which this revision belongs
} {
    return [db_string item_id {
        select item_id
        from cr_revisions
        where revision_id = :revision_id
    } -default ""]
}


ad_proc -public content::revision::read_xml {
    -item_id:required
    -revision_id:required
    -clob_loc:required
} {
    @param item_id
    @param revision_id
    @param clob_loc

    @return NUMBER
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list revision_id $revision_id ] \
        [list clob_loc $clob_loc ] \
    ] content_revision read_xml]
}


ad_proc -public content::revision::replace {
    -revision_id:required
    -search:required
    -replace:required
} {
    @param revision_id
    @param search
    @param replace
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
        [list search $search ] \
        [list replace $replace ] \
    ] content_revision replace]
}


ad_proc -public content::revision::revision_name {
    -revision_id:required
} {
    @param revision_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision revision_name]
}

ad_proc -public content::revision::get_title {
    -revision_id:required
} {

    Returns the title of a particular 'content_revision'.

    @param revision_id The 'revision_id' of the object

    @see content::item::get_title
    @see content::revision::revision_name

    @return The title of the object (text), or empty if not found.

} {
    return [db_string get_title {select title from cr_revisions where revision_id = :revision_id} -default ""]
}

ad_proc -public content::revision::to_html {
    -revision_id:required
} {
    @param revision_id
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision to_html]
}


ad_proc -public content::revision::to_temporary_clob {
    -revision_id:required
} {
    @param revision_id
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
    ] content_revision to_temporary_clob]
}


ad_proc -public content::revision::write_xml {
    -revision_id:required
    -clob_loc:required
} {
    @param revision_id
    @param clob_loc

    @return NUMBER
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
        [list clob_loc $clob_loc ] \
    ] content_revision write_xml]
}


ad_proc -public content::revision::update_attribute_index {
} {
} {
    return [package_exec_plsql content_revision update_attribute_index]
}


ad_proc -public content::revision::get_cr_file_path {
    -revision_id
} {
    Get the path to content in the filesystem
    @param revision_id

    @return path to filesystem stored revision content

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-27
} {
    # the file path is stored in filename column on oracle
    # and content in PostgreSQL, but we alias to filename so it makes
    # sense
    db_1row get_storage_key_and_path {}
    return [cr_fs_path $storage_area_key]${filename}
}

#
# ::content::revision::export_to_filesystem
#
# This function was previously part of
# fs::publish_versioned_object_to_file_system but the application
# packages should be fully agnostic to the storage_type
# implementation.

ad_proc ::content::revision::export_to_filesystem {
    -revision_id:required
    -storage_type:required
    -filename:required
} {
    Export the content of the provided revision to the named file in
    the file system.
} {
    ::content::revision::write_to_filesystem-$storage_type \
        -revision_id $revision_id \
        -filename $filename
}

ad_proc -private ::content::revision::export_to_filesystem-text {
    -revision_id:required
    -filename:required
} {
    Export the content of the provided revision to the named file in
    the file system.
} {
    set content [db_string select_object_content {
        select content from cr_revisions where revision_id = :revision_id
    }]
    set fp [open $filename w]
    puts $fp $content
    close $fp
}

ad_proc -private ::content::revision::export_to_filesystem-file {
    -revision_id:required
    -filename:required
} {
    Export the content of the provided revision to the named file in
    the file system.
} {
    set cr_file_name [content::revision::get_cr_file_path -revision_id $revision_id]

    #
    # Check if cr_file_name is not empty, otherwise we could end up copying the
    # whole content-repository.
    #
    if {$cr_file_name ne ""} {
        #
        # When there are multiple "unnamed files" in a directory, the
        # constructed filename might exist already. This would lead to an
        # error in the "file copy" operation. Therefore, generate a new
        # name with an alternate suffix in these cases.
        #
        set base_name $filename
        set count 0
        while {[ad_file exists $filename]} {
            set filename $base_name-[incr $count]
        }

        file copy -- $cr_file_name $filename
    } else {
        ad_log Warning "::content::revision::export_to_filesystem-file: \
            cr_file_name is empty (revision_id: $revision_id)"
    }
}

ad_proc -private ::content::revision::export_to_filesystem-lob {
    -revision_id:required
    -filename:required
} {
    Export the content of the provided revision to the named file in
    the file system.
} {
    db_blob_get_file select_object_content {} -file $filename
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
