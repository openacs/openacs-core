# 

ad_library {
    
    tsearch2 search engine driver installation procedures
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    @arch-tag: 2006927e-7f1d-41c9-a111-ac552a4da185
    @cvs-id $Id$
}

namespace eval tsearch2_driver::install {}

ad_proc -public tsearch2_driver::install::package_install {
} {
    
    Installation callback for tsearch2 search engine driver
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
 
    @error 
} {
    tsearch2_driver::install::register_fts_impl
}

ad_proc -private tsearch2_driver::install::register_fts_impl {
} {
    
    Register FtsEngineDriver service contract implementation
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    
    @return 
    
    @error 
} {

    set spec {
	name "tsearch2-driver"
	aliases {
	    search tsearch2::search
	    index tsearch2::index
	    unindex tsearch2::unindex
	    update_index tsearch2::update_index
	    summary tsearch2::summary
	    info tsearch2::driver_info
	}
	contract_name "FtsEngineDriver"
	owner "tsearch2-driver"
    }

    acs_sc::impl::new_from_spec -spec $spec
    
}

