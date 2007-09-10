-- Make sure that emails are going to parties not to users and therefore logging is for parties, not for users.
alter table acs_mail_lite_mail_log add column party_id integer references parties(party_id);
update acs_mail_lite_mail_log set party_id = user_id;
alter table acs_mail_lite_mail_log drop column user_id;

alter table acs_mail_lite_bounce add column party_id integer references parties(party_id);
update acs_mail_lite_bounce set party_id = user_id;
alter table acs_mail_lite_bounce drop column user_id;