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
}

set context [list "Users"]

db_1row users_n_users {}
db_1row users_deleted_users {}

set n_users [lc_numeric $n_users]
set last_registration [lc_time_fmt $last_registration "%q"]

set groups "<option value='' selected>--</option>\n"
append groups [db_html_select_value_options groups_select {
    select groups.group_id, groups.group_name
    from groups,
       (select distinct group_id from group_member_map) m,
       (select distinct group_id from group_component_map) c
    where groups.group_id = m.group_id
      and groups.group_id = c.group_id
    order by group_name
} ]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
