ad_page_contract {

    Toggles enabled_p of authority

    @author Simon Carstensen (simon@collaboraid.biz)

    @creation-date 2003-09-09
} {
    authority_id
    enabled_p:boolean
}

db_dml set_enabled_p { update auth_authorities set enabled_p = :enabled_p where authority_id = :authority_id }

ad_returnredirect . 
ad_script_abort
