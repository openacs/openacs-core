# Purpose: show summary of package specification (.info file)
#
# param: package_key (like acs-admin or lars-blogger)

array set info [apm_read_package_info_file [apm_package_info_file_path $package_key]]

set maturity [apm::package_version::attributes::maturity_int_to_text \
                  $info(maturity)]

# what packages does $package_key depend on
multirow create deps name
foreach p $info(requires) {
    multirow append deps [lindex $p 0]
}

# get installed packages which depend on $package_key
db_multirow dependees dependees {
    select v.package_key as name
      from apm_package_versions v, 
           apm_package_dependencies d 
     where v.version_id=d.version_id 
       and d.dependency_type='requires' 
       and d.service_uri=:package_key 
    order by v.package_key
}

# append uninstalled packages which depend on $package_key
apm_get_package_repository -array repository
foreach key [array names repository] {
    array unset pkg
    array set pkg $repository($key)
    set requires_list $pkg(requires)
    foreach require $requires_list {
        if { [string eq $package_key [lindex $require 0]] } {
            multirow append dependees $key
            break
        }
    }
}

