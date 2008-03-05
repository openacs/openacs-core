# 

ad_library {
    
    Tcl API for content_folders
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28
    @cvs-id $Id$
    
}

namespace eval ::content::folder {}

ad_proc -public ::content::folder::new {
    -name:required
    {-folder_id ""}
    {-parent_id ""}
    {-content_type "content_folder"}
    {-label ""}
    {-description ""}
    {-creation_user ""}
    {-creation_ip ""}
    -creation_date
    {-context_id ""}
    {-package_id ""}
} {
    
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28
    
    @param folder_id

    @param name

    @param parent_id

    @param content_type

    @param label

    @param description

    @param creation_user

    @param creation_ip

    @param creation_date

    @param context_id

    @param package_id

    @return 
    
    @error 
} {
    set var_list [list]
    foreach var [list folder_id name label description parent_id context_id package_id] {
	lappend var_list [list $var [set $var]]
    }
    if {[exists_and_not_null creation_date]} {
        lappend var_list [list creation_date $creation_date]
    }
    set folder_id [package_instantiate_object \
		     -creation_user $creation_user \
		     -creation_ip $creation_ip \
		     -var_list $var_list \
		     $content_type]
    return $folder_id
}

ad_proc -public ::content::folder::delete {
    -folder_id:required
    {-cascade_p "f"}
} {
    Delete a content folder
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28
    
    @param folder_id item_id of the content_folder
    @param cascade_p if true delete all children, if false, return error if folder is non-empty
    
    @return 
    
    @error 
} {
    return [package_exec_plsql \
		-var_list [list \
			       [list folder_id $folder_id ] \
			       [list cascade_p $cascade_p] ] \
		content_folder del]
}

ad_proc -public ::content::folder::register_content_type {
    -folder_id:required
    -content_type:required
    {-include_subtypes "f"}
} {
    Register an allowed content type for folder_id
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-29
    
    @param folder_id folder to register type to

    @param content_type content_revision or subtype of content_revision

    @param include_subtypes t or f

    @return 
    
    @error 
} {
    return [package_exec_plsql \
                -var_list [list \
                               [list folder_id $folder_id] \
                               [list content_type $content_type] \
                               [list include_subtypes $include_subtypes]] \
                content_folder register_content_type]
}


ad_proc -public ::content::folder::unregister_content_type {
    -folder_id:required
    -content_type:required
    {-include_subtypes "f"}
} {
    Unregister an allowed content type for folder_id
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-04
    
    @param folder_id folder to unregister type from

    @param content_type content_revision or subtype of content_revision

    @param include_subtypes t or f

    @return 
    
    @error 
} {

    return [package_exec_plsql \
                -var_list [list \
                               [list folder_id $folder_id] \
                               [list content_type $content_type] \
                               [list include_subtypes $include_subtypes]] \
                content_folder unregister_content_type]
}

ad_proc -public ::content::folder::update {
    -folder_id:required
    -attributes:required
} {
    Update standard cr_folder attributes, including the attributes for
    the folder cr_item
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-04
    
    @param folder_id folder to update

    @param attributes A list of pairs of additional attributes and
    their values to set. Each pair is a list of lists of two elements:
    key => value
    Valid attributes are: label, description, name, package_id

    @return 
    
    @error 
} {
    set valid_attributes [list label description package_id]

    set update_text "" 

    foreach {attribute_list} $attributes {
	set attribute [lindex $attribute_list 0]
	set value [lindex $attribute_list 1]	
	if {[lsearch $valid_attributes $attribute] > -1}  {

	    # create local variable to use for binding

	    set $attribute $value
	    if {$update_text ne ""} {
		append update_text ","
	    }
	    append update_text " ${attribute} = :${attribute} "
   	}
    }
    if {$update_text ne ""} {

	# we have valid attributes, update them

	set query_text "update cr_folders set ${update_text} where folder_id=:folder_id"
	db_dml item_update $query_text
    }

    # pass the rest of the attributes to content::item::update
    # we can just send the folder attributes because they don't overlap
    content::item::update \
	-item_id $folder_id \
	-attributes $attributes
}


ad_proc -public content::folder::get_index_page {
    -folder_id:required
} {
    @param folder_id

    @return item_id of content item named "index" in folder_id
} {
    return [package_exec_plsql \
		-var_list [list [list \
			       folder_id $folder_id \
				    ]] \
		content_folder get_index_page]
}


ad_proc -public content::folder::get_label {
    -folder_id:required
} {
    @param folder_id 

    @return label of cr_folder suitable for display
} {
    return [package_exec_plsql \
		-var_list [list \
			       [list folder_id $folder_id] \
			      ] \
		content_folder get_label]
}


ad_proc -public content::folder::is_empty {
    -folder_id:required
} {
    @param folder_id

    @return t or f
} {
    return [package_exec_plsql \
		-var_list [list \
			       [list folder_id $folder_id ] \
			      ] \
		content_folder is_empty]
}


ad_proc -public content::folder::is_folder {
    -item_id:required
} {
    @param item_id

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
           [list item_id $item_id] \
    ] content_folder is_folder]
}


ad_proc -public content::folder::is_registered {
    -folder_id:required
    -content_type:required
    {-include_subtypes ""}
} {
    @param folder_id
    @param content_type
    @param include_subtypes

    @return t or f
} {
    return [package_exec_plsql \
		-var_list [list \
			       [list folder_id $folder_id] \
			       [list content_type $content_type] \
                               [list include_subtypes $include_subtypes] \
			      ] \
		content_folder is_registered]
}


ad_proc -public content::folder::is_root {
    -folder_id:required
} {
    @param folder_id

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
                                              [list folder_id $folder_id] \
    ] content_folder is_root]
}


ad_proc -public content::folder::is_sub_folder {
    -folder_id:required
    -target_folder_id:required
} {
    @param folder_id
    @param target_folder_id

    @return t of f 
} {
    return [package_exec_plsql \
		-var_list [list \
			       [list folder_id $folder_id] \
			       [list target_folder_id $target_folder_id] \
			      ] \
		content_folder is_sub_folder]
}

ad_proc content::folder::get_folder_from_package {
    -package_id:required
} {
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-01-06

    Returns the folder_id of the package instance. Cached
} {
    return [util_memoize [list content::folder::get_folder_from_package_not_cached -package_id $package_id]]
}

ad_proc content::folder::get_folder_from_package_not_cached {
    -package_id:required
} {
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-01-06

    Returns the folder_id of the package instance
} {
    return [db_string get_folder_id "select folder_id from cr_folders where package_id=:package_id"]
}
