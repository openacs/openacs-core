# $Id$
#
# sessions-registered-summary.tcl
#
# by philg@mit.edu sometime in 1999
#
# displays a table of number of users who haven't logged in 
# for X days

set_the_usual_form_variables 0

# go_beyond_60_days_p (optional; default is to limit to 60 days)

append whole_page "[ad_admin_header "Registered Sessions"]

<h2>Registered Sessions</h2>

[ad_context_bar [list "./" "Users"] "Registered Sessions"]

<hr>

<blockquote>

<table cellpadding=5>
<tr>
  <th>N Days Since Last Visit<th>Total Sessions<th>Repeat Sessions
</tr>

"



# we have to query for pretty month and year separately because Oracle pads
# month with spaces that we need to trim

set selection [ns_db select $db "select round(sysdate-last_visit) as n_days, count(*) as n_sessions, count(second_to_last_visit) as n_repeats
from users
where last_visit is not null
group by round(sysdate-last_visit)
order by 1"]

set table_rows ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $n_days > 60 && (![info exists go_beyond_60_days_p] || !$go_beyond_60_days_p) } {
	append table_rows "<tr><td colspan=3 align=center>&nbsp;</td></tr>\n"
	append table_rows "<tr><td colspan=3 align=center><a href=\"sessions-registered-summary?go_beyond_60_days_p=1\">go beyond 60 days...</a></td></tr>\n"
	ns_db flush $db
	break
    }
    append table_rows "<tr><th>$n_days<td align=right><a href=\"action-choose?last_login_equals_days=$n_days\">$n_sessions</a><td align=right>$n_repeats</tr>\n"
}

db_release_unused_handles

append whole_page "$table_rows
</table>

</blockquote>

[ad_admin_footer]
"
ns_return 200 text/html $whole_page
