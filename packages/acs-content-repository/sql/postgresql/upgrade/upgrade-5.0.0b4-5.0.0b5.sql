-- this one tried to assign an aliased variable bug 1281.
--
create or replace function content_keyword__is_assigned (integer,integer,varchar)
returns boolean as '
declare
  is_assigned__item_id                alias for $1;  
  is_assigned__keyword_id             alias for $2;  
  is_assigned__recurse                alias for $3;  -- default ''none''  
  v_ret                               boolean;    
  v_is_assigned__recurse	      varchar;
begin
  if is_assigned__recurse is null then 
	v_is_assigned__recurse := ''none'';
  else
      	v_is_assigned__recurse := is_assigned__recurse;	
  end if;

  -- Look for an exact match
  if v_is_assigned__recurse = ''none'' then
      return count(*) > 0 from cr_item_keyword_map
       where item_id = is_assigned__item_id
         and keyword_id = is_assigned__keyword_id;
  end if;

  -- Look from specific to general
  if v_is_assigned__recurse = ''up'' then
      return count(*) > 0
      where exists (select 1
                    from (select keyword_id from cr_keywords c, cr_keywords c2
	                  where c2.keyword_id = is_assigned__keyword_id
                            and c.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)) t,
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);
  end if;

  if v_is_assigned__recurse = ''down'' then
      return count(*) > 0
      where exists (select 1
                    from (select k2.keyword_id
                          from cr_keywords k1, cr_keywords k2
                          where k1.keyword_id = is_assigned__keyword_id
                            and k1.tree_sortkey between k2.tree_sortkey and tree_right(k2.tree_sortkey)) t, 
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);

  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise EXCEPTION ''-20000: The recurse parameter to content_keyword.is_assigned should be \\\'none\\\', \\\'up\\\' or \\\'down\\\''';
  
  return null;
end;' language 'plpgsql' stable;

