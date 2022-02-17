-- Captcha data-model
-- Note: in Postgres we can define the default for expiration as "one
-- hour from now". This is apparently trickier in Oracle, so the
-- default as defined by the datamodel is equal to automatic failure
-- for the captcha check. In practice, this is fine, because the
-- actual expiration we set in the widget code.

create table template_widget_captchas (
   image_checksum text primary key,
   text text not null,
   expiration timestamp not null default current_timestamp
);

create index template_widget_captchas_expiration_idx on template_widget_captchas(expiration);
