<queryset>
   <rdbms><type>postgresql</type><version>8.3</version></rdbms>

  <fullquery name="tsearch2::index.index">
    <querytext>
      insert into txt (object_id,fti)
      values (:object_id,
              setweight(to_tsvector(coalesce(:title,'')),'A')
              ||setweight(to_tsvector(coalesce(:keywords,'')),'B')
              ||to_tsvector(coalesce(:txt,'')))
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::search.base_query">
    <querytext>
      where fti @@ to_tsquery(:query)
        and exists (select 1
                    from acs_object_party_privilege_map m
                    where m.object_id = txt.object_id
                      and m.party_id = :user_id
                      and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::search.search">
    <querytext>
      select txt.object_id $base_query
      order by ts_rank(fti,to_tsquery(:query)) desc
      $limit_clause $offset_clause
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::summary.summary">
    <querytext>
      select ts_headline(:txt,to_tsquery(:query))
    </querytext>
  </fullquery>

</queryset>

<queryset>
  <rdbms><type>postgresql</type><version>8.0</version></rdbms>

  <fullquery name="tsearch2::index.index">
    <querytext>
      insert into txt (object_id,fti)
      values (:object_id,
              setweight(to_tsvector('default',coalesce(:title,'')),'A')
              ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
              ||to_tsvector('default',coalesce(:txt,'')))
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::search.base_query">
    <querytext>
      where fti @@ to_tsquery('default',:query)
        and exists (select 1
                    from acs_object_party_privilege_map m
                    where m.object_id = txt.object_id
                      and m.party_id = :user_id
                      and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::search.search">
    <querytext>
      select txt.object_id $base_query
      order by rank(fti,to_tsquery('default',:query)) desc
      $limit_clause $offset_clause
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::summary.summary">
    <querytext>
      select headline('default',:txt,to_tsquery('default',:query))
    </querytext>
  </fullquery>

</queryset>

</queryset>
