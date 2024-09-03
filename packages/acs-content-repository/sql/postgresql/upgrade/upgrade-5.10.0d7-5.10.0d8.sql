begin;

-- S.C. implementations have been renamed to comply with OpenACS
-- naming convention

update acs_sc_impl_aliases set
  impl_alias = 'content_search::datasource'
where impl_alias = 'content_search__datasource';

update acs_sc_impl_aliases set
  impl_alias = 'content_search::url'
where impl_alias = 'content_search__url';

update acs_sc_impl_aliases set
  impl_alias = 'image_search::datasource'
where impl_alias = 'image_search__datasource';

update acs_sc_impl_aliases set
  impl_alias = 'image_search::url'
where impl_alias = 'image_search__url';

update acs_sc_impl_aliases set
  impl_alias = 'template_search::datasource'
where impl_alias = 'template_search__datasource';

update acs_sc_impl_aliases set
  impl_alias = 'template_search::url'
where impl_alias = 'template_search__url';


end;
