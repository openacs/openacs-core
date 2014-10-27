ad_page_contract {
    @cvs-id $Id$
} {
} -properties {
    title:onevalue
    context:onevalue
    discussion_forum_alert_p:onevalue
    bboard_keyword_p:onevalue
    bboard_rows:multirow
    classified_email_alert_p:onevalue
    classified_rows:multirow
    gc_system_name:onevalue
}

set user_id [ad_conn user_id]

db_1row name_get "select first_names, last_name, email, url from persons, parties where persons.person_id = parties.party_id and party_id =:user_id" -bind [ad_tcl_vars_to_ns_set user_id]

if { $first_names ne "" || $last_name ne "" } {
    set full_name "$first_names $last_name"
} else {
    set full_name "name unknown"
}

set title "$full_name's alerts in [ad_system_name]"

set context [list "Alerts"]


set discussion_forum_alert_p 0
set classified_email_alert_p 0

if { [db_table_exists "bboard_email_alerts"] } {
    set discussion_forum_alert_p 1

    set rownum 0

    if { [bboard_pls_blade_installed_p] == 1 } {
	set bboard_keyword_p 1
    } else {
	set bboard_keyword_p 0
    }
	
    db_foreach alerts_list "
    select bea.valid_p, bea.frequency, bea.keywords, bt.topic, bea.rowid
    from bboard_email_alerts bea, bboard_topics bt
    where bea.user_id = :user_id
    and bea.topic_id = bt.topic_id
    order by bea.frequency" {
	incr rownum

	if { $valid_p == "f" } {
	    # alert has been disabled for some reason
	    set bboard_rows:$rownum(status) "disable"
	    set bboard_rows:$rownum(action_url) "/bboard/alert-reenable?rowid=[ns_urlencode $rowid]"	    
	} else {
	    # alert is enabled
	    set bboard_rows:$rownum(status) "enable"
	    set bboard_rows:$rownum(action_url) "/bboard/alert-disable?rowid=[ns_urlencode $rowid]"	    
	}

	set bboard_rows:$rownum(topic) $topic
	set bboard_rows:$rownum(frequency) $frequency
	set bboard_rows:$rownum(keywords) $keywords
	
    } if_no_rows {
	set discussion_forum_alert_p 0
    }
}


if { [db_table_exists "classified_email_alerts"] } {
    set classified_email_alert_p 1
    
    set gc_system_name [gc_system_name]
    set rownum 0

    db_foreach alerts_list_2 "
    select cea.valid_p,
           ad.domain,
           cea.alert_id,
           cea.expires,
           cea.frequency,
           cea.alert_type,
           cea.category,
           cea.keywords
    from   classified_email_alerts cea, ad_domains ad
    where  user_id = :user_id
    and    ad.domain_id = cea.domain_id
    and    sysdate <= expires
    order by expires desc" {
	incr rownum
	
	if { $valid_p == "f" } {
	    # alert has been disabled for some reason
	    set classified_rows:$rownum(status) "Off"
	    set classified_rows:$rownum(action) "<a href=\"/gc/alert-reenable?alert_id=$alert_id\">Re-enable</a>"
	} else {
	    # alert is enabled
	    set classified_rows:$rownum(status) "<font color=red>On</font>"
	    set classified_rows:$rownum(action) "<a href=\"/gc/alert-disable?rowid=$rowid\">Disable</a>"
	}

	if { $alert_type eq "all" } {
	    set classified_rows:$rownum(alert_value) "--"
	} elseif { $alert_type eq "keywords" } {
	    set classified_rows:$rownum(alert_value) $keywords
	} elseif { $alert_type eq "category" } {
	    set classified_rows:$rownum(alert_value) $category
	} else {
	    # I don't know what to do here...
	    set classified_rows:$rownum(alert_value) "--"
	}

	set classified_rows:$rownum(domain) $domain
	set classified_rows:$rownum(rowid) $row_id
	set classified_rows:$rownum(expires) $expires
	set classified_rows:$rownum(frequency) [gc_PrettyFrequency $frequency]
	set classified_rows:$rownum(alert_type) $alert_type
	
    } if_no_rows {
	set classified_email_alert_p 0
    }
}

db_release_unused_handles

ad_return_template