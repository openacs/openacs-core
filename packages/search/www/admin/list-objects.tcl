ad_page_contract {
    Search admin index page

    @author openacs@dirkgomez.de
} {
  object_type

} -properties {
}                                                                                                                           
set context [list "Search Admin Page"]

db_multirow objects_per_type objects_per_type {
  select object_name, swi.object_id 
  from acs_objects ao, site_wide_index swi 
  where swi.object_id=ao.object_id 
  and ao.object_type=:object_type
    order by object_id}