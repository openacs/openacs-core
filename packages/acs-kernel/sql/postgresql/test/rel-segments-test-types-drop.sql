
select drop_package('blah_member_rel');
select drop_package('yippie_member_rel');

drop table blah_member_rels;
drop table yippie_member_rels;

begin;

    select acs_rel_type__drop_type('blah_member_rel','f');

    select acs_rel_type__drop_type('yippie_member_rel','f');

end;
