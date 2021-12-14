ad_library {

    Tests for api in /tcl/apm-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_package_load_libraries_order
    } \
    apm_dependencies_api {
        Make sure result from the dependencies api matches the
        expected result from the data model.
    } {
        foreach package_key [db_list get_packages {
            select package_key from apm_package_types
        }] {
            set db_dependencies [db_list get_dependencies {
                with recursive dependencies as
                (
                 select apv.package_key,
                        apd.service_uri as dependency_package_key
                  from apm_package_versions apv, apm_package_dependencies apd
                 where apv.package_key = :package_key
                   and apv.installed_p = 't'
                   and apd.version_id = apv.version_id
                   and apd.dependency_type in ('requires', 'embeds', 'extends')

                 union

                 select apv.package_key,
                        apd.service_uri as dependency_package_key
                   from apm_package_versions apv,
                        apm_package_dependencies apd,
                        dependencies d
                  where apv.package_key = d.dependency_package_key
                    and apv.installed_p = 't'
                    and apd.version_id = apv.version_id
                    and apd.dependency_type in ('requires', 'embeds', 'extends')
                 )
                select distinct dependency_package_key
                from dependencies
            }]
            lappend db_dependencies $package_key

            set api_dependencies [apm_package_load_libraries_order $package_key]
            aa_equals "Dependencies from api and db for '$package_key' are the same" \
                [lsort $api_dependencies] \
                [lsort $db_dependencies]
        }
    }
