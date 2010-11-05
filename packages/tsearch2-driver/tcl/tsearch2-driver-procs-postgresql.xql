<queryset>

  <fullquery name="tsearch2::index.index">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      insert into txt (object_id,fti)
      values (:object_id,
              setweight(to_tsvector(coalesce(:title,'')),'A')
              ||setweight(to_tsvector(coalesce(:keywords,'')),'B')
              ||to_tsvector(coalesce(:txt,'')))
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.base_query"> 
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      where fti @@ to_tsquery(:query)
        and exists (select 1
                    from acs_object_party_privilege_map m
                    where m.object_id = txt.object_id
                      and m.party_id = :user_id
                      and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.search">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      select txt.object_id
      from
      [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and " : ""}]
      [join $where_clauses " and "]
      order by ts_rank(fti,to_tsquery(:query)) desc
      $limit_clause $offset_clause
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.count">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      select count(*)
      from
      [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and " : ""}]
      [join $where_clauses " and "]
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::summary.summary">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      select ts_headline(:txt,to_tsquery(:query))
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::update_index.update_index">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
       update txt set fti =
         setweight(to_tsvector(coalesce(:title,'')),'A')
           ||setweight(to_tsvector(coalesce(:keywords,'')),'B')
           ||to_tsvector(coalesce(:txt,''))
         where object_id=:object_id
    </querytext>   
  </fullquery>

  <fullquery name="tsearch2::index.index">
  <rdbms><type>postgresql</type><version>8.0</version></rdbms>
    <querytext>
      insert into txt (object_id,fti)
      values (:object_id,
              setweight(to_tsvector('default',coalesce(:title,'')),'A')
              ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
              ||to_tsvector('default',coalesce(:txt,'')))
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.base_query">
  <rdbms><type>postgresql</type><version>8.0</version></rdbms>
    <querytext>
      where fti @@ to_tsquery('default',:query)
        and exists (select 1
                    from acs_object_party_privilege_map m
                    where m.object_id = txt.object_id
                      and m.party_id = :user_id
                      and m.privilege = 'read')
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.search">
  <rdbms><type>postgresql</type><version>8.0</version></rdbms>
    <querytext>
      select txt.object_id
      from
      [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and " : ""}]
      [join $where_clauses " and "]
      order by rank(fti,to_tsquery('default',:query)) desc
      $limit_clause $offset_clause
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.count">
  <rdbms><type>postgresql</type><version>8.2</version></rdbms>
    <querytext>
      select count(*)
      from
      [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and " : ""}]
      [join $where_clauses " and "]
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::summary.summary">
  <rdbms><type>postgresql</type><version>8.0</version></rdbms>
    <querytext>
      select headline('default',:txt,to_tsquery('default',:query))
    </querytext>
  </fullquery>

  <fullquery name="tsearch2::update_index.update_index">
  <rdbms><type>postgresql</type><version>8.0</version></rdbms>
    <querytext>
       update txt set fti =
         setweight(to_tsvector('default',coalesce(:title,'')),'A')
           ||setweight(to_tsvector('default',coalesce(:keywords,'')),'B')
           ||to_tsvector('default',coalesce(:txt,''))
         where object_id=:object_id
    </querytext>   
  </fullquery>

</queryset>
