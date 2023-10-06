ad_page_contract {
    Consolidated the various toggle pages into one.
    
    @author Lars Pind (lars@pinds.com)
    @author Jeff Davis <davis@xarg.net>
    @creation-date 2003-10-28
    @cvs-id $Id$
} {
    field 
    enabled_p:boolean,notnull
    {return_url:localurl "."}
}

ds_require_permission [ad_conn package_id] "admin"

switch -- $field {
    com {
        parameter::set_value -package_id [ds_instance_id] -parameter ShowCommentsInlineP -value $enabled_p
    }
    adp {
        ds_set_adp_reveal_enabled $enabled_p
    }
    db {
        ds_set_database_enabled $enabled_p
    }
    prof {
        ds_set_profiling_enabled $enabled_p
    }
    ds {
        nsv_set ds_properties enabled_p $enabled_p
        set ::ds_enabled_p $enabled_p
    }
    frag {
        nsv_set ds_properties page_fragment_cache_p $enabled_p
    }
    user {
        ds_set_user_switching_enabled $enabled_p
    }
    default { 
        ad_return_complaint 1 "bad field $field"
        ad_script_abort
    }
}
ad_returnredirect $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
