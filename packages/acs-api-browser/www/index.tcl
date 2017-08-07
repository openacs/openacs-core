ad_page_contract {
    
    Offers links to other pages, and lets the user type the name of a specific procedure.
    If about_package_key is set to an installed package, then this page will automatically
    return /package-view page for the package-key, which is a handy way of integrating
    static docs with evolving api, especially for core packages.

    @about_package_key a package-key
    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @cvs-id $Id$
} {
    about_package_key:token,trim,optional
} -properties {
    title:onevalue
    context:onevalue
    installed_packages:multirow
    disabled_packages:multirow
    uninstalled_packages:multirow
}

set title "API Browser"
set context [list]

if  { [info exists about_package_key] } {

    # create multirows to make property-passing happy
    multirow create installed_packages
    multirow create disabled_packages
    multirow create uninstalled_packages

    if { [db_0or1row get_local_package_version_id {} ] } {
        rp_form_update version_id $version_id
        rp_internal_redirect package-view
    }

} else {

    db_multirow installed_packages installed_packages_select {
        select version_id, pretty_name, version_name
          from apm_package_version_info
        where installed_p = 't'
          and enabled_p = 't'
      order by upper(pretty_name)
    }

    db_multirow disabled_packages disabled_packages_select {
        select version_id, pretty_name, version_name
          from apm_package_version_info
         where installed_p = 't'
           and enabled_p = 'f'
      order by upper(pretty_name)
    }

    db_multirow uninstalled_packages uninstalled_packages_select {
        select version_id, pretty_name, version_name
          from apm_package_version_info
         where installed_p = 'f'
           and enabled_p = 'f'
      order by upper(pretty_name)
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
