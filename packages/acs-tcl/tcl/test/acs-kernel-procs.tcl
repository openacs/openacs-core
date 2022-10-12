ad_library {

    Tests for api in tcl/acs-kernel-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_acs_admin_node
        ad_acs_kernel_id
        ad_acs_release_date
        ad_acs_version
        apm_version_get
        apm_version_id_from_package_key
    } \
    acs_system_information_api {
        Test the API that returns information about the system.
    } {
        aa_equals "The node_id of acs-admin is returned as expected" \
            [ad_acs_admin_node] \
            [db_string query {
                select node_id from site_nodes n, apm_packages p
                where n.object_id = p.package_id
                and p.package_key = 'acs-admin'
            }]

        aa_equals "The acs-kernel package_id is returned as expected" \
            [ad_acs_kernel_id] \
            [db_string query {
                select package_id from apm_packages
                where package_key = 'acs-kernel'
            }]

        aa_equals "The acs-kernel release date is returned as expected" \
            [ad_acs_release_date] \
            [db_string query {
                select to_char(release_date, 'YYYY-MM-DD')
                  from apm_package_versions
                where enabled_p = 't'
                  and package_key = 'acs-kernel'
            }]

        aa_equals "The acs-kernel version is returned as expected" \
            [ad_acs_version] \
            [db_string query {
                select version_name
                  from apm_package_versions
                where enabled_p = 't'
                  and package_key = 'acs-kernel'
            }]
    }
