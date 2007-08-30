# packages/acs-content-repository/tcl/acs-content-repository-callback-procs.tcl

ad_library {
    
    Callback procs for acs-content-repository
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-15
    @arch-tag: d9aec4df-102d-4b0d-8d0e-3dc470dbe783
    @cvs-id $Id$
}


ad_proc -public -callback subsite::parameter_changed -impl acs-content-repository {
    -package_id:required
    -parameter:required
    -value:required
} {
    Implementation of subsite::parameter_changed for acs-content-repository.
    
    This is needed as we can change the CRFileLocationRoot parameter. As the cr_fs_path is stored in an NSV we would need to
    update the NSV the moment we change the parameter so we don't need to restart the server.
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2005-10-29
    
    @param package_id the package_id of the package the parameter was changed for
    @param parameter  the parameter name
    @param value      the new value
    
} {
    ns_log Debug "subsite::parameter_changed -impl acs-content-repository called for $parameter"
    
    set package_key [apm_package_key_from_id $package_id]
    
    if {$package_key eq "acs-content-repository" && $parameter eq "CRFileLocationRoot" && $value ne ""} {
        nsv_unset CR_LOCATIONS CR_FILES
	
	# Take the directory from the FileLocation parameter that 
	# must be specified in acs-content-repository package.
	set relativepath_p [parameter::get_from_package_key -package_key "acs-content-repository" -parameter FileLocationRelativeP]
	set file_location ""
	
	if {$relativepath_p} {
	    # The file location is relative to acs_root_dir
	    append file_location "[acs_root_dir]/"
	}
	append file_location [parameter::get_from_package_key -package_key "acs-content-repository" -parameter "CRFileLocationRoot" -default "content-repository-content-files"]
	
	nsv_set CR_LOCATIONS CR_FILES "$file_location"
	
    } else {
	ns_log Debug "subsite::parameter_changed -impl acs-content-repository don't care about $parameter"
    }
}
