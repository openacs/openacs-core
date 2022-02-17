--
-- Captcha data-model
--

create table template_widget_captchas (
   image_checksum  varchar2(4000) primary key,
   text            varchar2(4000) not null,
   expiration      timestamp default (sysdate + interval '1' hour )
                   constraint template_widget_captchas_nn not null
);

create index template_widget_captchas_expiration_idx on template_widget_captchas(expiration);
