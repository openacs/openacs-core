<queryset>

  <fullquery name="tsearch2::index.index">
    <querytext>
      with index as (
       select setweight(to_tsvector(coalesce(:title,'')),'A')
            ||setweight(to_tsvector(coalesce(:keywords,'')),'B')
            ||to_tsvector(coalesce(:txt,'')) as fti
       from dual
      ),
      insert as (
      insert into txt (object_id, fti)
        select o.object_id, i.fti
          from acs_objects o, index i
         where object_id = :object_id
           and not exists (select 1 from txt
                            where object_id = o.object_id)
      )
      update txt set
        fti = (select fti from index)
       where object_id = :object_id
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
      select count(distinct(orig_object_id)) from acs_permission.permission_p_recursive_array(array(
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
