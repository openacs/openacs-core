<?xml version="1.0"?>
<queryset>

<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="template::list::prepare.pagination_query">
    <querytext>
      select * from (
        select paginate.*, rownum rowsub from
          ($list_properties(page_query_substed)) paginate
        where rownum <= $last_row)
      where rowsub >= $first_row
    </querytext>
  </fullquery>

</queryset>
