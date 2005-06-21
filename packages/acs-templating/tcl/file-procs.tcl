namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template {}
namespace eval template::util {}
namespace eval template::util::file {}


ad_proc -private template::data::transform::file { element_ref } {
    @return the list { file_name temp_file_name content_mime_type }.
} {
    upvar $element_ref element
    return [list [template::util::file_transform $element(id)]]
}

ad_proc -public template::util::file_transform { element_id } {
    Helper proc, which gets AOLserver's variables from the query/form, and returns it as a 'file' datatype value.
    @return the list { file_name temp_file_name content_mime_type }.
} {
    # Work around Windows bullshit
    set filename [ns_queryget $element_id]

    if { [string equal $filename ""] } {
        return ""
    }

    regsub -all {\\+} $filename {/} filename
    regsub -all { +} $filename {_} filename
    set filename [lindex [split $filename "/"] end]
    return [list $filename [ns_queryget $element_id.tmpfile] [ns_queryget $element_id.content-type]]

}

ad_proc -public template::data::validate::file { value_ref message_ref } {
    Our file widget can't fail 

    @return true
} {
    return 1
}

ad_proc -public template::util::file::get_property { what file_list } {

    switch $what {
        filename {
            return [lindex $file_list 0]
        }
        tmp_filename {
            return [lindex $file_list 1]
        }
        mime_type {
            return [lindex $file_list 2]
        }
    }

}

ad_proc -private template::util::file::generate_filename {
    {-title:required}
    {-extension:required}
    {-existing_filenames ""}
    {-party_id ""}
} {
    Generate a pretty filename that relates to the title supplied and is unique

    @param party_id if supplied the filenames associated with this party will be used as existing_filenames if existing filenames is not provided

    @param existing_filenames a list of filenames that the generated filename must not be equal to
} {
    if {[exists_and_not_null party_id] 
	&& [string is integer $party_id] && ![exists_and_not_null existing_filenames]} {
	set existing_filenames [db_list get_parties_existing_filenames {}]
    }
    set filename [util_text_to_url \
		      -text ${title} -replacement "_"]
    set output_filename "${filename}.${extension}"
    set num 1
    while {[lsearch $existing_filenames $output_filename] >= 0} {
	set output_filename "${filename}${num}.${extension}"
	incr num
    }
    return $output_filename
}

ad_proc -private template::util::file::get_file_extension {
    {-filename:required}
} {
    get the file extension from a file
} {
    return [lindex [split $filename "."] end]
}


ad_proc -public template::util::file::store_for_party {
    {-upload_file:required}
    {-party_id:required}
    {-package_id ""}
} {
    Store the file uploaded under the party_id if a file was uploaded
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-21
    
    @param upload_file

    @param party_id

    @return the revision_id of the generated item
    
    @error 
} {

    set filename [template::util::file::get_property filename $upload_file]
    if {$filename != "" } {
	set tmp_filename [template::util::file::get_property tmp_filename $upload_file]
	set mime_type [template::util::file::get_property mime_type $upload_file]
	set tmp_size [file size $tmp_filename]
	set extension [lindex [split $filename "."] end]
	if {![exists_and_not_null title]} {
	    regsub -all ".${extension}\$" $filename "" title
	}
	set filename [template::util::file::generate_filename \
			  -title $title \
			  -extension $extension \
			  -party_id $party_id]

	
        set revision_id [cr_import_content \
			     -storage_type "file" -title $title -package_id $package_id $party_id $tmp_filename $tmp_size $mime_type $filename]

	content::item::set_live_revision -revision_id $revision_id

	return $revision_id
    } 
}
