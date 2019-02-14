ad_library {
    procedures to support intermedia search engine for Oracle
}

ad_proc -public -callback search::index -impl intermedia-driver {} {
    Search Index Callback for Oracle Intermedia
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-06-12

} {
    # we want the datasource array reference in case we want to do something clever
    if {$datasource ne ""} {
        upvar $datasource _datasource
    }
    set content "${title} ${content}"
    # if storage type is file, store the text in the site_wide_index table
    if {![db_string index_exists "select 1 from site_wide_index where object_id=:object_id" -default 0]} {
        db_dml index "insert into site_wide_index
                     (object_id, object_name, package_id, relevant_date, community_id, indexed_content)
                     values
                     (:object_id, :title, :package_id, :relevant_date, :community_id, empty_clob() )
                     returning indexed_content into :1" -clobs [list $content]


    } else {
        # call the update index proc since this object is already indexed
        callback -impl intermedia-driver search::update_index \
            -object_id $object_id \
            -content $content \
            -title $title \
            -keywords $keywords \
            -community_id $community_id \
            -relevant_date $relevant_date \
            -description $description \
            -datasource $datasource \
            -package_id $package_id

    }

}

ad_proc -public -callback search::update_index -impl intermedia-driver {} {
   Update item in the index
   @author Dave Bauer (dave@thedesignexperience.org
   @creation-date 2005-08-01
} {
    if {$datasource ne ""} {
        upvar $datasource _datasource
    }
    if {![db_string index_exists "select 1 from site_wide_index where object_id=:object_id" -default 0]} {
        callback -impl intermedia-driver search::index \
            -object_id $object_id \
            -content $content \
            -title $title \
            -keywords $keywords \
            -community_id $community_id \
            -relevant_date $relevant_date \
            -description $description \
            -datasource $datasource \
            -package_id $package_id
        return
    } else {
        db_dml index "update site_wide_index
                      set object_name=:title,
                          package_id=:package_id,
                          community_id=:community_id,
                          relevant_date=:relevant_date,
                          indexed_content=empty_clob()
                          where object_id=:object_id
                      returning indexed_content into :1" -clobs [list $content]
    }
}

ad_proc -public -callback search::unindex -impl intermedia-driver {} {
    Remove item from search index
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-06-12
} {
    db_dml unindex "delete from site_wide_index where object_id=:object_id"
}

ad_proc -public -callback search::search -impl intermedia-driver {} {
    Search full text index
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-05-29

    @param query
    @param offset
    @param limit
    @param user_id
    @param df
    @param dt
    @param package_ids
    @param object_type
} {
    if {[info exists package_ids] && [llength $package_ids]} {
        set package_ids_clause " and swi.package_id in ([template::util::tcl_to_sql_list $package_ids]) "
    } else {
        set package_ids_clause ""
    }

    if {[info exists object_type] && $object_type eq "forums"} {
        set object_type_clause " and o.object_type in ('forums_forum', 'forums_message') "
    } elseif {[info exists object_type] && $object_type ne "all" } {
        set object_type_clause " and o.object_type = :object_type "
    } else {
        set object_type_clause ""
    }

    set weighted_score "score(10) - case when object_type='faq'
              then nvl(months_between(sysdate,relevant_date)/4,20)
            when object_type='forums'
              then nvl(months_between(sysdate,relevant_date)*1.5,20)
            when object_type='phb_person'
              then 0
            when object_type='news'
              then nvl(months_between(sysdate,relevant_date)*2,20)
            when object_type='cal_item'
              then nvl(months_between(sysdate,relevant_date)*2,20)
            when object_type='file_storage_object'
              then nvl(months_between(sysdate,relevant_date)*1.5,20)
            when object_type='survey'
              then nvl(months_between(sysdate,relevant_date)*1.5,20)
            when object_type='static_portal_content'
              then nvl(months_between(sysdate,relevant_date)*1.5,20)
            end"

    set people_search_clause { o.object_type = 'phb_person' or }
    if {[apm_package_installed_p "dotlrn"]} {
        set is_guest_p [db_string get_is_guest_p {select dotlrn_privacy.guest_p(:user_id) from dual}]
        if {$is_guest_p} {
            set people_search_clause { and }; # doesn't look like legal SQL
        }

        set is_member {
          exists ( select 1
                   from dotlrn_member_rels_approved
                   where community_id = swi.community_id
                     and user_id = :user_id)}
        set community_id_clause " and (swi.community_id is null or $is_member) "
        set member_clause " and $is_member "
    } else {
        set community_id_clause {}
        set member_clause {}
    }

    set results_ids [db_list search "select s.object_id from
          (select rownum as r,o.object_id

          from site_wide_index swi, acs_objects o
          where swi.object_id= o.object_id
          $object_type_clause
          and contains (swi.indexed_content,:query, 10)> 0
          and (
          $people_search_clause
          (exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = o.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read')
          $community_id_clause))
                    $package_ids_clause
                   order by $weighted_score desc) s where r > $offset and r <= $offset + $limit"]
    # TODO implement stopwords reporting for user query

    set count [db_string count "select count(swi.object_id) from site_wide_index swi, acs_objects o where o.object_id=swi.object_id $object_type_clause and contains (swi.indexed_content,:query)> 0
          and (
          $people_search_clause
          (exists (select 1
                   from acs_object_party_privilege_map m
                   where m.object_id = o.object_id
                     and m.party_id = :user_id
                     and m.privilege = 'read')
          $member_clause))
                   $package_ids_clause "]
    set stop_words ""
    ns_log notice "
-----------------------------------------------------------------------------
DAVEB99 intermedia::search
query = '{$query}'
package_ids = '${package_ids}'
return = '[list ids $results_ids stopwords $stop_words count $count]'
-----------------------------------------------------------------------------
"
    return [list ids $results_ids stopwords $stop_words count $count]
}

ad_proc -public -callback search::summary -impl intermedia-driver {
} {
    Get summary for an object

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-05-29

    @param object_id

} {
    # TODO implement intermedia::summary
    return [string range $text 0 100]
}

ad_proc -public -callback search::driver_info -impl intermedia-driver {
} {
    Info for the service contract implementation
    for intermedia

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-05-29

} {
    return [list package_key intermedia-driver version 1 automatic_and_queries_p 1  stopwords_p 1]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
