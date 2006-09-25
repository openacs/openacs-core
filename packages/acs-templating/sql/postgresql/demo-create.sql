create sequence ad_template_sample_users_seq start 5 increment 1;
create view ad_template_sample_users_sequence as select nextval('ad_template_sample_users_seq') as nextval;

create table ad_template_sample_users (
       user_id         integer 
		       constraint ad_template_sample_users_pk primary key,
       first_name      varchar(20),
       last_name       varchar(20),
       address1        varchar(40),
       address2        varchar(40),
       city            varchar(40),
       state           varchar(2)
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

\i template-demo-notes-create.sql
\i template-demo-notes-sample.sql

