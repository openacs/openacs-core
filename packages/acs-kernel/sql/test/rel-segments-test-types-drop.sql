
drop package blah_member_rel;
drop package yippe_member_rel;

drop table blah_member_rels;
drop table yippe_member_rels;

begin

    acs_rel_type.drop_type('blah_member_rel');

    acs_rel_type.drop_type('yippe_member_rel');

end;
/
show errors
