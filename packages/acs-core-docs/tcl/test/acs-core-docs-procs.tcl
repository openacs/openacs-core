ad_library {
    Automated tests for the acs-core-docs package.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2020-08-19
    @cvs-id $Id$
}

aa_register_case -procs {
        ad_core_docs_uninstalled_packages
    } -cats {
        api
        production_safe
    } dd_core_docs_uninstalled_packages {
        Test ad_core_docs_uninstalled_packages proc.
} {
    #
    # List of uninstalled packages
    #
    set non_installed [ad_core_docs_uninstalled_packages]
    #
    # Check if the packages are indeed not installed
    #
    dict for {key name} $non_installed {
        aa_false "$key is installed" "[apm_package_installed_p $key]"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
