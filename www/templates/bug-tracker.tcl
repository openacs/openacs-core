# Purpose: Show a quick summary of bug-tracker information about a
# specific OpenACS package.
# param: package_key (such as acs-admin or lars-blogger)

# Each OpenACS package is represented in the bugtracker as a
# component.  The component name is unfortunately not exactly the same
# as the package_key, so it needs to be massaged.

# We take care of all the special cases and handle the default at the
# end.  Most package_key(s) can be converted to component_name(s) by
# simply removing the dashes

switch $package_key {
    openacs {set component_name "1-OpenACS General"}
    acs-bootstrap-installer {set component_name "ACS Bootstrap/Installer"}
    acs-core-docs {set component_name "ACS Core Documents"}
    acs-lang {set component_name "ACS Language"}
    acs-ldap-authentication {set component_name "ACS LDAP Authentication (deprecated)"}
    adserver {set component_name "Ad Server"}
    authorize-gateway {set component_name "Authorize.net Gateway"}
    acs-automated-testing {set component_name "Automated Testing"}
    bug-tracker {set component_name "BugTracker"}
    dotlrn-fs {set component_name "dotLRN File Storage Applet"}
    dotlrn-wps {set component_name "dotLRN Wimpy Point Applet"}
    fs-portlet {set component_name "File Storage Portlet"}
    ims-ent {set component_name "IMS Enterprise"}
    payflowpro {set component_name "PayflowPro Gateway"}
    ref-timezones {set component_name "Reference Data - Timezone"}
    ref-us-zipcodes {set component_name "Reference Data - US Zip Codes"}
    spam {set component_name "Spam System"}
    theme-selva {set component_name "theme-selva"}
    oacs-dav {set component_name "WebDAV Support"}
    wp-slim {set component_name "Wimpy Point Slim"}
    xml-rpc {set component_name "XML-RPC"}
    default {set component_name [string map {"-" " "} $package_key]}
}

if { [db_0or1row pkg_exists "select component_id from bt_components where lower(component_name)=lower(:component_name)"] } {
    set pkg_exists_p 1
    
    set all_bugs_query "
	select bug_number, summary, to_char(creation_date, 'YYYY-MM-DD') as date,
               st.short_name
	from bt_bugs b, 
             workflow_cases c, 
             workflow_case_fsm fsm, 
             workflow_fsm_states st
	where b.component_id=:component_id
          and b.bug_id=c.object_id
          and c.case_id=fsm.case_id
          and fsm.current_state=st.state_id
        order by creation_date desc
    "

    # walk through all the bugs, counting the open bugs
    # and saving the most recent bug and fix
    set open 0; set bug_exists_p 0; set fix_exists_p 0
    db_foreach all_bugs $all_bugs_query {
	if { $short_name eq "open" } {
	    incr open
	    if { ! $bug_exists_p } {
		# most recent bug entered
		set bug_exists_p 1
		array set bug [list summary $summary num $bug_number date $date]
	    }
	} else {
	    if { ! $fix_exists_p } {
		# most recent bug fixed
		set fix_exists_p 1
		array set fix [list summary $summary num $bug_number date $date]
	    }
	}
    }

    # find prolific submitter
    db_multirow submitters submitters "
      select creation_user as user_id,
             count(bug_id) as count 
        from bt_bugs
       where component_id=:component_id 
       group by creation_user 
       order by count(bug_id) desc 
       limit 5"

    # find prolific fixer
    # This query overcounts if a bug is resolved more than once. But
    # it's a huge pain to find out the true resolver in those cases,
    # so I'm keeping the overcount
    db_multirow fixers fixers "
	select count(b.bug_id) as count, 
               o.creation_user as user_id
	from bt_bugs b, 
             workflow_cases c, 
             workflow_case_log l,
             workflow_actions a,             
             acs_objects o
	where b.component_id=:component_id
          and b.bug_id=c.object_id
          and c.case_id=l.case_id
          and l.action_id=a.action_id
          and a.short_name='resolve'
          and l.entry_id=o.object_id
        group by o.creation_user
        order by count(b.bug_id) desc
        limit 5"
} else {
    set pkg_exists_p 0
}

