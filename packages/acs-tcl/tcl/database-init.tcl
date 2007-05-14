ad_library {

    Initialization code for database routines.

    @creation-date 7 Aug 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$

}

#DRB: the default value is needed during the initial install of OpenACS
ns_cache create db_cache_pool -size \
    [parameter::get_from_package_key  \
        -package_key acs-kernel \
        -parameter DBCacheSize -default 50000]
