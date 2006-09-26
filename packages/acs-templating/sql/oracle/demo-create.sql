create sequence ad_template_sample_users_seq start with 5 increment by 1;

create table ad_template_sample_users (
       user_id         integer 
                       constraint ad_template_sample_users_pk primary key,
       first_name      varchar2(20),
       last_name       varchar2(20),
       address1        varchar2(40),
       address2        varchar2(40),
       city            varchar2(40),
       state           varchar2(2)
);


insert into ad_template_sample_users values 
 (1, 'Fred', 'Jones', '101 Main St.', NULL, 'Orange', 'CA');
                
insert into ad_template_sample_users values 
 (2, 'Frieda', 'Mae', 'Lexington Hospital', '102 Central St.', 
      'Orange', 'CA');

insert into ad_template_sample_users values 
 (3, 'Sally', 'Saxberg', 'Board of Supervisors', '1933 Fruitvale St.', 
      'Woodstock', 'CA');

insert into ad_template_sample_users values 
 (4, 'Yoruba', 'Diaz', '12 Magic Ave.', NULL, 'Lariot', 'WY');

-- load jiml's notes-like package
@@ template-demo-notes-create.sql
@@ template-demo-notes-sample.sql

