ad_page_contract {
    Disables a version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
}

apm_version_disable -callback apm_dummy_callback $version_id

ad_returnredirect "version-view?version_id=$version_id"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
