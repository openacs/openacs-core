# 

ad_page_contract {
    
    List of all CSS files in the system
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2007-09-29
    @cvs-id $Id$
} {
    {return_url:localurl ""}
    {css_list}
} -properties {
} -validate {
} -errors {
}

ds_require_permission [ad_conn package_id] "admin"

template::multirow create css_multirow css_location file_location edit_url
foreach css $css_list {
    set css_path_list [split $css "/"]
    set path_root [lindex $css_path_list 1]
    if { $path_root eq "resources"} {
	set file_location "[acs_package_root_dir [lindex $css_path_list 2]]/www/resources/[join [lrange $css_path_list 3 end] /]"
	set edit_location [export_vars -base "css-edit" -url {file_location return_url {css_location $css}}]
    } elseif {[apm_version_id_from_package_key $path_root] ne ""} {
	# THis is a package key, but not resources directory
	set package_key $path_root
	set file_location "[acs_package_root_dir $package_key]/www/[join [lrange $css_path_list 2 end] /]"
	set edit_location [export_vars -base "css-edit" -url {file_location return_url {css_location $css}}]
    } else {
	set file_location $css
	set edit_location ""
    }
    template::multirow append css_multirow $css $file_location $edit_location
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
