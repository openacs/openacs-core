--
-- packages/acs-subsite/sql/email-image-drop.sql
--
-- author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
-- creation-date 2005-01-22
--

select acs_rel_type__drop_type('email_image_rel', 'f');
select acs_rel_type__drop_role('email_image');

drop table email_images;
