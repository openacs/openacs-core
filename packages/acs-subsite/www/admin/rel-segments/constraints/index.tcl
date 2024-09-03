ad_page_contract {

    Shows all constraints on which the user has read permission

    @author mbryzek@arsdigita.com
    @creation-date Fri Dec 15 11:30:52 2000
    @cvs-id $Id$

}

set context    [list [list ../ "Relational segments"] "Constraints"]
set user_id    [ad_conn user_id]
set package_id [ad_conn package_id]

# Select out basic information about all the constraints on which the
# user has read permission

db_multirow constraints select_rel_constraints {
    select c.constraint_id, c.constraint_name
      from rel_constraints c
           application_group_segments s1, application_group_segments s2
     where s1.segment_id = c.rel_segment
       and s1.package_id = :package_id
       and s2.segment_id = c.required_rel_segment
       and s2.package_id = :package_id
       and acs_permission.permission_p(c.constraint_id, :user_id, 'read')
     order by lower(c.constraint_name)
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
