ad_page_contract { 
    Enables a version of the package.
    
    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @creation-date 9 May 2000
    @cvs-id $Id$
} {
    {version_id:integer}

}

apm_version_enable -callback apm_dummy_callback $version_id

ad_returnredirect "version-view?version_id=$version_id"
