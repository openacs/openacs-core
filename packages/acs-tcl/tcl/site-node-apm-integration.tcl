ad_library {

    site node / apm integration procs

    @author arjun (arjun@openforce.net)
    @author yon (yon@openforce.net)
    @creation-date 2002-07-10
    @version $Id$

}

namespace eval site_node_apm_integration {

    ad_proc -public get_child_package_id {
        {-package_id ""}
        {-package_key:required}
    } {
        get the package_id of package_key that is mounted directly under
        package_id. returns empty string if not found.
    } {
        if {[empty_string_p $package_id]} {
            set package_id [ad_conn package_id]
        }

        return [db_string select_child_package_id {} -default ""]
    }

    ad_proc -public child_package_exists_p {
        {-package_id ""}
        {-package_key:required}
    } {
        Returns 1 if there exists a child package with the given package_key, 
        or 0 if not.
    } {
        set child_package_id [get_child_package_id \
            -package_id $package_id \
            -package_key $package_key
        ]

        if {[empty_string_p $child_package_id]} {
            return 0
        } else {
            return 1 
        }
    }

}
