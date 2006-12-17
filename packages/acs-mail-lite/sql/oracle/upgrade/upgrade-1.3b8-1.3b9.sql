-- Make sure that emails are going to parties not to users and therefore logging is for parties, not for users.
alter table acs_mail_lite_bounce_notif drop constraint acs_mail_li_bou_notif_us_id_fk;
alter table acs_mail_lite_bounce_notif add column party_id integer constraint acs_mail_li_bou_notif_us_id_fk references parties (party_id) on delete cascade;
update acs_mail_lite_bounce_notif set party_id = user_id;
alter table acs_mail_lite_bounce_notif drop column user_id;