-- Captcha data-model (untested)

create table template_widget_captchas (
   image_checksum text primary key,
   text text not null,
   expiration timestamp not null default current_timestamp + cast('1 hour' as interval)
);

create index template_widget_captchas_expiration_idx on template_widget_captchas(expiration);
