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
    {-attributes}
    {-is_live "f"}
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

    if {![exists_and_not_null content_type]} {
	set content_type [::content::item::content_type -item_id $item_id]
    }
    set attribute_names ""
    set attribute_values ""
    set lob_values [list]

    if { [exists_and_not_null attributes] } {
	set type_attributes [package_object_attribute_list $content_type]
	set valid_attributes [list]
	# add in extended attributes for this type, ingore
	# content_revision as those are already captured as named
	# parameters to this procedure
	
	foreach type_attribute $type_attributes {
	    if {![string equal "cr_revisions" [lindex $type_attribute 1]]} {
		if {[db_type] == "oracle" && [string equal "text" [lindex $type_attribute 4]]} {
		    set lob_attributes([lindex $type_attribute 2]) [list [lindex $type_attribute 7] [lindex $type_attribute 8]]
		} else {
		    lappend valid_attributes [lindex $type_attribute 2]
		}
	    }
	}
	foreach attribute_pair $attributes {
            foreach {attribute_name attribute_value} $attribute_pair {break}
	    if {[lsearch $valid_attributes $attribute_name] > -1} {
                # first add the column name to the list
		append attribute_names  ", ${attribute_name}"		
		# create local variable to use for binding
		set $attribute_name $attribute_value
		append attribute_values ", :${attribute_name}"
	    }
	    if {[info exists lob_attributes($attribute_name)]} {
		lappend lob_values $attribute_name $attribute_value [lindex $lob_attributes($attribute_name) 0] [lindex $lob_attributes($attribute_name) 1]
	    }
	}
    }
    
    set table_name [db_string get_table_name "select table_name from acs_object_types where object_type=:content_type"]
    set table_name "${table_name}i"

    set query_text "insert into ${table_name}
                    (revision_id, object_type, creation_user, creation_date, creation_ip, title, description, item_id, mime_type $attribute_names)
            values (:revision_id, :content_type, :creation_user, :creation_date, :creation_ip, :title, :description, :item_id, :mime_type $attribute_values)"
    db_transaction {
        if {[string equal "" $revision_id]} {
	    set revision_id [db_nextval "acs_object_id_seq"]
	}
        db_dml insert_revision $query_text
        update_content \
            -revision_id $revision_id \
            -content $content
	foreach {lob_attribute lob_value lob_table lob_id_column} $lob_values {
	    db_dml update_lob_attribute {} -clobs [list $lob_value]
	}
    }
ns_log notice "
DB --------------------------------------------------------------------------------
DB DAVE debugging /var/lib/aolserver/openacs-5-1/packages/acs-content-repository/tcl/content-revision-procs.tcl
DB --------------------------------------------------------------------------------
DB is_live = '${is_live}' \n
DB revision_id = '${revision_id}'"
    if {[string is true $is_live]} {
        content::item::set_live_revision -revision_id $revision_id
    }
    return $revision_id
}

ad_proc -public content::revision::update_content {
    -revision_id
    -content
} {
    
    Update content column seperately. Oracle does not allow insert
    into a BLOB.
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-02-09
    
    @param revision_id Content revision to update

    @param content Content to add to resivsion

    @return 
    
    @error 
} {
    db_dml update_content "" -blobs [list $content]
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

