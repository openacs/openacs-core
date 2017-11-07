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
  <rdbms><type>postgresql</type><version>8.4</version></rdbms>
    <querytext>
      where fti @@ to_tsquery(:query)
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.search">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      select txt.object_id
      from [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and " : ""}]
      [join $where_clauses " and "]
      order by ts_rank(fti,to_tsquery(:query)) desc
      $limit_clause $offset_clause
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.search">
  <rdbms><type>postgresql</type><version>8.4</version></rdbms>
    <querytext>
        select distinct(orig_object_id) from acs_permission.permission_p_recursive_array(array(
           select txt.object_id
           from [join $from_clauses ","]
           $base_query
           [expr {[llength $where_clauses] > 0 ? " and [join $where_clauses { and }]" : ""}]
           order by ts_rank(fti,to_tsquery(:query)) desc
        ), :user_id, 'read')
        $limit_clause $offset_clause
    </querytext>
  </fullquery>

  <fullquery name="callback::search::search::impl::tsearch2-driver.count">
  <rdbms><type>postgresql</type><version>8.3</version></rdbms>
    <querytext>
      select count(*)
      from [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and [join $where_clauses { and }]" : ""}]
    </querytext>
  </fullquery>

  <fullquery name="dbqd.tsearch2-driver.tcl.tsearch2-driver-procs.callback::search::search::impl::tsearch2-driver.search_result_count">
  <rdbms><type>postgresql</type><version>8.4</version></rdbms>
    <querytext>
      select count(distinct(orig_object_id)) from acs_permission__permission_p_recursive_array(array(
      select txt.object_id
      from [join $from_clauses ","]
      $base_query
      [expr {[llength $where_clauses] > 0 ? " and " : ""}]
      [join $where_clauses " and "]
        ), :user_id, 'read')
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

</queryset>
