ad_page_contract {
    Search admin index page

    @author openacs@dirkgomez.de
} {
  object_type

} -properties {
}                                                                                                                           
db_dml delete_object_type_from_index {delete from site_wide_index where object_id in (select object_id from acs_objects where object_type=:object_type)}

ad_returnredirect ./index
