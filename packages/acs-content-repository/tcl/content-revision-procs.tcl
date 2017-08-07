# 

ad_library {
    
    Procedures to manipulate content revisions
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-04
    @arch-tag: ddc736fb-cb5f-41fe-a854-703df26e8e03
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

    @param tmp_filename file containing content to be added to revision. Caller is responsible to handle cleaning up the tmp file
    @param package_id

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
	set content_type [::content::item::content_type -item_id $item_id]
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
	# add in extended attributes for this type, ingore
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
    
    set table_name [db_string get_table_name {
        select table_name from acs_object_types where object_type = :content_type
    }]

    set mime_type [cr_check_mime_type \
                       -filename  $title \
                       -mime_type $mime_type \
                       -file      $tmp_filename]
    
    set query_text "insert into ${table_name}i
                    (revision_id, object_type, creation_user, creation_date, creation_ip, title, description, item_id, object_package_id, mime_type $attribute_names)
            values (:revision_id, :content_type, :creation_user, :creation_date, :creation_ip, :title, :description, :item_id, :package_id, :mime_type $attribute_values)"
    db_transaction {
        # An explict lock was necessary for PostgreSQL between 8.0 and
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

ad_proc -public ::content::revision::update_content {
    -item_id
    -revision_id
    -content
    -storage_type
    -mime_type 
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
    @param tmp_filename For file storage type a filename can be specified. It will be added to the contnet repository. Caller is responsible to handle cleaning up the tmp file

    @return 
    
    @error 
} {

     switch $storage_type {
	file {
	    if {$tmp_filename eq ""} {
                set filename [cr_create_content_file_from_string $item_id $revision_id $content]
	    } else {
                set filename [cr_create_content_file $item_id $revision_id $tmp_filename]
            }
	    set tmp_size [file size [cr_fs_path]$filename]            
	    db_dml set_file_content ""
	}
	lob {
	    if {$tmp_filename ne ""} {
		# handle file
		set filename [cr_create_content_file $item_id $revision_id $tmp_filename]		
	        db_dml set_lob_content "" -blob_files [list $tmp_filename]
	        db_dml set_lob_size ""
	    } else {
		# handle blob
		db_dml update_content "" -blobs [list $content]
	    }
	}
	default {
		# HAM : 112505
		# I added a default switch because in some cases
		#   storage type is text and revision is not being updated
		db_dml update_content "" -blobs [list $content]
	}
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
    return [db_string item_id {} -default ""]
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
    # and content in postgresql, but we alias to filename so it makes
    # sense
    db_1row get_storage_key_and_path ""
    return [cr_fs_path $storage_area_key]${filename}
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
