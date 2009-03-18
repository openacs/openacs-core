-- Make sure that emails are going to parties not to users and 
-- therefore logging is for parties, not for users.
alter table acs_mail_lite_mail_log add party_id integer constraint amlml_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_mail_log set party_id = user_id;
alter table acs_mail_lite_mail_log drop column user_id;

alter table acs_mail_lite_bounce add party_id integer constraint amlb_party_id_fk references parties(party_id) on delete cascade;
update acs_mail_lite_bounce set party_id = user_id;
alter table acs_mail_lite_bounce drop column user_id;

alter table acs_mail_lite_bounce_notif drop constraint acs_mail_li_bou_notif_us_id_fk;
alter table acs_mail_lite_bounce_notif add party_id integer constraint amlbn_party_id_fk references parties (party_id) on delete cascade;
update acs_mail_lite_bounce_notif set party_id = user_id;
alter table acs_mail_lite_bounce_notif drop column user_id;

