# ad_proc ad_admin_users_index_dot_tcl_whole_page {} {

    ad_page_contract {
	by a bunch of folks including philg@mit.edu and teadams@arsdigita.com
	modified by philg on October 30, 1999 to cache the page
	(sequentially scanning through users and such was slowing it down)
	
	modified by aure@caltech.edu on February 4, 2000 to make the page more
	user friendly
	
	we define this procedure here in the file because we don't care if
	it gets reparsed; it is RDBMS load that was slowing stuff down.  We also  
	want programmers to have an easy way to edit this page.

	@cvs-id $Id$
	@author Multiple
    } {} -properties {
	context:onevalue
	n_users:onevalue
	n_deleted_users:onevalue
	last_registration:onevalue
        groups:onevalue
    }

    set context [list "Users"]

    db_1row users_n_users {}
    db_1row users_deleted_users {}

    set n_users [util_commify_number $n_users]
    set last_registration [lc_time_fmt $last_registration "%q"]

set groups [db_html_select_value_options groups_select {
select groups.group_id, 
       groups.group_name, 
       m.num as n_members, 
       c.num as n_components 
from groups, 
     (select group_id, count(*) as num 
      from group_member_map group by group_id) m, 
     (select group_id, count(*) as num 
      from group_component_map group by group_id) c 
where groups.group_id=m.group_id 
  and groups.group_id = c.group_id
order by group_name
} ]

    ad_return_template

# }

# doc_return 200 text/html [util_memoize "ad_admin_users_index_dot_tcl_whole_page"]


# The code below used to be in this file, but was temporarily taken out for ACS 4.0

#  set state_list ""

#      db_foreach member_states "select count(member_state) 
#      as num_in_state, member_state
#      from cc_users 
#      group by member_state" {
#  	set member_state_num($member_state) [util_commify_number $num_in_state]
#      }

#      if {[ad_parameter RegistrationRequiresApprovalP "" 0] && [info exists member_state_num(need_admin_approv)]} {
#  	lappend state_list "<a href=action-choose?member_state=need_admin_approv>need_admin_approv</a> ($member_state_num(need_admin_approv))"
#      }

#      if {[ad_parameter RegistrationRequiresApprovalP "" 0] && [ad_parameter RegistrationRequiresEmailVerificationP "" 0] && [info exists member_state_num(need_email_verification_and_admin_approv)]} {
#  	lappend state_list "<a href=action-choose?member_state=need_email_verification_and_admin_approv>need_email_verification_and_admin_approv</a>  ($member_state_num(need_email_verification_and_admin_approv))"
#      }

#      if {[ad_parameter RegistrationRequiresEmailVerificationP "" 0] && [info exists member_state_num(need_email_verification)]} {
#  	lappend state_list "<a href=action-choose?member_state=need_email_verification>need_email_verification</a> ($member_state_num(need_email_verification))"
#      }

#      if [info exists member_state_num(authorized)] {
#  	lappend state_list "<a href=action-choose?member_state=authorized>authorized</a> ($member_state_num(authorized))"
#      }

#      if [info exists member_state_num(banned)] {
#  	lappend state_list "<a href=action-choose?member_state=banned>banned</a>  ($member_state_num(banned))"
#      }

#      if [info exists member_state_num(deleted)] {
#  	lappend state_list "<a href=action-choose?member_state=deleted>deleted</a>  ($member_state_num(deleted))"
#      }

#      append whole_page "  
#      <li>Users in state: [join $state_list " | "]
#      <p>
#      "


    # XXX Not in ACS 40, but will be added later
    #  db_1row user_sessions "
    #  select 
    #    sum(session_count) as total_sessions, 
    #    sum(repeat_count) as total_repeats
    #  from session_statistics"

    #  if [empty_string_p $total_sessions] {
    #      set total_sessions 0
    #  }
    #  if [empty_string_p $total_repeats] {
    #      set total_repeats 0
    #  }

    #  set spam_count [db_string unused "
    #  select sum(n_sent) from spam_history"]
    #  if [empty_string_p $spam_count] {
    #      set spam_count 0
    #  } 


    #  <li>registered sessions:  <a href=\"sessions-registered-summary\">by days since last login</a>
    #  <li>total sessions (includes unregistered users): 
    #  <a href=\"session-history\">[util_commify_number $total_sessions] ([util_commify_number $total_repeats] repeats)</a>
    # <p>

    #  <li><a href=\"/admin/spam/\">Review spam history</a> 
    #  ([util_commify_number $spam_count] sent) 


#      append whole_page "
#      <h3>Pick a user class</h3>
#      <ul>
#      <table cellspacing=1 border=0>
#      <tr bgcolor=[next_color $bgcolor]>
#      <form method=post action=action-choose>
#      "

#      if {[db_table_exists country_codes]} {
#  	if {[ad_parameter InternationalP "" 1]} {
#  	    # there are some international users 
#  	    append whole_page "<tr bgcolor=[next_color $bgcolor]><td align=right>Country:</td><td> 
#  	    <select name=country_code>
#  	    <option></option>
#  	    [db_html_select_value_options countries_select_options "select c.iso, c.country_name || ' - ' || count(user_id) || ' users'
#  	    from users_contact uc, country_codes c
#  	    where uc.ha_country_code = c.iso
#  	    group by c.country_name, c.iso
#  	    order by lower(c.country_name)"]
#  	    </select></td></tr>
#  	    "
#  	}
#      }

#      if { [db_table_exists users_contact] && [ad_parameter SomeAmericanReadersP "" 1]} {
#  	append whole_page "<tr bgcolor=[next_color $bgcolor]><td align=right>State:</td><td>
#  	<select name=usps_abbrev>
#  	<option></option>
#  	[db_html_select_value_options states_select_options "select s.usps_abbrev, s.state_name || ' - ' || count(user_id) || ' users'
#  	from users_contact uc, states s
#  	where uc.ha_state = s.usps_abbrev
#  	and (uc.ha_country_code is null or uc.ha_country_code = 'us')
#  	group by s.state_name, s.usps_abbrev
#  	order by lower(s.state_name)"]
#  	</select></td></tr>"
#      }

    #old query
#      "select user_groups.group_id, group_name || ' - ' || count(user_id) || ' users'
#      from user_groups, user_group_map
#      where user_groups.group_id = user_group_map.group_id
#      group by user_groups.group_id, group_name
#      order by lower(group_name)"
#      append whole_page "
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Group:</td>
#      <td><select name=group_id>
#      <option></option>
#      [db_html_select_value_options user_groups_select_options "select groups.group_id, group_name || ' - ' || count(member_id) || ' users'
#      from groups, group_member_map gm
#      where groups.group_id = gm.group_id
#      group by groups.group_id, group_name
#      order by lower(group_name)"
#      ]
#      </select>
#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Age:</td>
#      <td>
#      <table border=0 cellpadding=2 cellspacing=0>
#      <tr><td align=right>
#      over</td><td> <input type=text size=3 name=age_above_years> years 
#      </td></tr> 
#      <tr><td align=right>
#      under</td><td> <input type=text size=3 name=age_below_years> years
#      </td></tr></table>

#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Registration date:</td>
#      <td>
#      <table border=0 cellpadding=2 cellspacing=0>
#      <tr><td align=right>
#      over</td><td> <input type=text size=3 name=registration_before_days> days ago
#      </td></tr> 
#      <tr><td align=right>
#      under</td><td> <input type=text size=3 name=registration_after_days> days ago
#      </td></tr></table>
#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Last login:</td>
#      <td>
#      <table border=0 cellpadding=2 cellspacing=0>
#      <tr><td align=right>
#      over</td><td> <input type=text size=3 name=last_login_before_days> days ago
#      </td></tr> 
#      <tr><td align=right>
#      under</td><td> <input type=text size=3 name=last_login_after_days> days ago
#      </td></tr></table>
#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Number of visits:</td>
#      <td>
#      <table border=0 cellpadding=2 cellspacing=0>
#      <tr><td align=right>
#      less than</td><td> <input type=text size=3 name=number_visits_below>
#      </td></tr>
#      <tr><td align=right>
#      more than </td><td><input type=text size=3 name=number_visits_above>
#      </td></tr></table>
#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Last name starts with:</td>
#      <td>
#      <input type=text name=last_name_starts_with>
#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td align=right>Email starts with:</td>
#      <td> <input type=text name=email_starts_with>
#      </td>
#      </tr>
#      <tr bgcolor=[next_color $bgcolor]>
#      <td>&nbsp;</td>
#      <td>
#      Join the above criteria by <input type=radio name=combine_method value=\"and\" checked> and <input type=radio name=combine_method value=\"or\"> or 
#      </td>
#      </tr>
#      <tr>
#      <td colspan=2 align=center>
#      <input type=submit name=Submit value=Submit>
#      </td>
#      </tr>
#      </form>
#      </table>
#      </ul>
#      </ul>"

#      if {[ad_parameter AllowAdminSQLQueries "" 0] == 1} {
#  	append whole_page "<blockquote>
#  	<h3>Select by SQL</h3>
#  	<form action=action-choose method=post>
#  	select users.* <br>
#  	<textarea cols=40 rows=4 name=sql_post_select></textarea><br>
#  	<i>example: from users where user_id < 1000</i>
#  	<center>
#  	<input type=submit name=submit value=Submit>
#  	</center>
#  	</form>
#  	</blockquote>"
#      }




