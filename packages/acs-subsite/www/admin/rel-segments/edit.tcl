ad_page_contract {

    Form to edit the name of a relational segment

    @author lars@collaboraid.biz
    @creation-date 2003-06-11
    @cvs-id $Id$

} {
    segment_id:integer,notnull
} -validate {
    segment_exists_p -requires {segment_id:notnull} {
	if { ![rel_segments_permission_p $segment_id] } {
	    ad_complain "The segment either does not exist or you do not have permission to view it"
	}
    }
    segment_in_scope_p -requires {segment_id:notnull segment_exists_p} {
	if { ![application_group::contains_segment_p -segment_id $segment_id]} {
	    ad_complain "The segment either does not exist or does not belong to this subsite."
	}
    }
}

set view_url [export_vars -base one { segment_id }]

set context [list [list "./" "Relational segments"] [list $view_url "One segment"] "Edit"]

ad_form -name segment -cancel_url $view_url -form {
    {segment_id:integer(hidden),key}
    {segment_name:text
        {label "Name"}
        {html {size 50}}
    }
} -select_query {
    select s.segment_id, 
           s.segment_name
    from   rel_segments s
    where  s.segment_id = :segment_id
} -edit_data {
    db_dml update_segment_name {
        update rel_segments
        set    segment_name = :segment_name
        where  segment_id = :segment_id
    }
} -after_submit {
    ad_returnredirect $view_url
    ad_script_abort
}
