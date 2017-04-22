#

ad_library {
    
    tsearch2 search engine driver installation procedures
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-05
    @arch-tag: 2006927e-7f1d-41c9-a111-ac552a4da185
    @cvs-id $Id$
}

namespace eval tsearch2_driver::install {}


ad_proc -public tsearch2_driver::install::preinstall_checks {

} {
    
    Make sure postgresql_contrib and tsearch are installed
    before allowing the installation of tsearch2_package
    
    @author Hamilton Chua (hchua@8tons.dyndns.biz)
    @creation-date 2004-07-02
    
} {

	ns_log Notice " ********** STARTING BEFORE-INSTALL CALLBACK ****************"

	# check if tsearch2 is installed
	# in psql we do this by checking the presence of a data type tsvector
	# select typname from pg_type where typename='tsvector';

	if { [db_0or1row tsearch_compile_check {
	    select distinct(typname) from pg_type where typname='tsvector'
	}] } {
	    # if tsearch is installed
	    ns_log Notice "******* Tsearch2 is compiled and installed. ***********"
	    # continue with installation
	} else {
	
		# tsearch not installed
		ns_log Notice "******* Tsearch2 is not installed. ***********"

                # RPM, Debian, source default locations
                set locs [list "/usr/share/pgsql/contrib/tsearch2.sql" \
                              "/usr/local/pgsql/contrib/tsearch2.sql" \
                              "/usr/local/pgsql/share/contrib/tsearch2.sql" \
                              "/usr/share/postgresql/contrib/tsearch2.sql"]
                foreach loc $locs {
                    if { [file exists $loc] } {
                        set sql_file_loc $loc
                        break
                    }
                }
		# Check if we've found it, run the sql file		
		if { ([info exists sql_file_loc] && $sql_file_loc ne "") } {
			# we found tsearch2.sql let's run it
			db_source_sql_file $sql_file_loc
		} else {
			# we could not find tserach2.sql, abort the install
			ns_log Notice "************************************************"
			ns_log Notice "********* Can't locate tsearch2.sql. ***********"
			ns_log Notice "********* Install tsearch2.sql manually ********"
			ns_log Notice "************************************************"
			ad_script_abort
		}
		
	}
	ns_log Notice " ********** ENDING BEFORE-INSTALL CALLBACK ****************"
	     
}

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

