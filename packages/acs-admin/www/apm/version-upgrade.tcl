ad_page_contract {

    Upgrades an older version of a package to one that a newer version that is locally
    maintained.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Thu Oct 12 17:45:38 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
}
apm_version_info $version_id

set title "Upgrading to $pretty_name $version_name"
set context [list \
		 [list "/acs-admin/apm/" "Package Manager"] \
		 [list "version-view?version_id=$version_id" "$pretty_name $version_name"] \
		 $title]

# Disable all previous versions of this packae.
apm_version_upgrade $version_id

# Instruct user to run SQL upgrade scripts.
set body [subst {
    <p>
    $pretty_name $version_name has been enabled.  Please run any necessary
    SQL upgrade scripts to finish updating the data model and restart
    the server.
}]

ad_return_template apm

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
