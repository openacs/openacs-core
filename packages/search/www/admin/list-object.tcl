ad_page_contract {
    Search admin index page

    @author openacs@dirkgomez.de
} {
  object_id

} -properties {
}                                                                                                                           
set context [list "Search Admin Page"]

db_1row get_object_content {
  select object_name, indexed_content, package_id, community_id
  from site_wide_index swi 
  where object_id=:object_id
    order by object_id}