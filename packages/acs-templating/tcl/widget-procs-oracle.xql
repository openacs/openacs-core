<?xml version="1.0"?>
<queryset>

<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="template::data::transform::party_search.search_persons">      
      <querytext>
        select (first_names || ' ' || last_name) as name, pe.person_id from persons pe, parties pa 
        where pe.person_id=pa.party_id and (
          lower(pe.first_names || ' ' || pe.last_name) like '%' || lower(:search_string) || '%'
          or lower(pa.email) like '%' || lower(:search_string) || '%'
	)
        order by lower(first_names || ' ' || last_name)
      </querytext>
</fullquery>

<fullquery name="template::data::transform::party_search.search_groups_relsegs">
      <querytext>
        (
        select g1.group_name as party_name, g1.group_id as party_id from groups g1
        where lower(g1.group_name) like '%' || lower(:search_string) || '%'
        )
        union
        (
        select g2.group_name || ' : ' || s2.segment_name as party_name, s2.segment_id as party_id
        from rel_segments s2, groups g2  
        where s2.group_id=g2.group_id and
        lower(g2.group_name || ' : ' || s2.segment_name) like '%' || lower(:search_string) || '%'
        )
        order by party_name
      </querytext>
</fullquery>

</queryset>
