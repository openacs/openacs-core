

create table best_friends (
  first_names 	varchar2(40),
  last_name 	varchar2(40),
  age 		integer,
  gender	char(1) check (gender in ('m', 'f')),
  address 	varchar2(300),
  likes_chocolate_p char(1) check (likes_chocolate_p in ('t','f')),
  email 	varchar(100));


insert into best_friends
    (first_names, last_name, age, gender, address, likes_chocolate_p, email)
  values
    ('Antonio', 'Davis', 24, 'm', '452 Hawkins Rd', 'f', 'antonio@nobody.com');

insert into best_friends
    (first_names, last_name, age, gender, address, likes_chocolate_p, email)
  values
    ('Matt', 'Carrier', 23, 'm', '345 Crystal City', null, 'matt@nobodoy.com');

insert into best_friends
    (first_names, last_name, age, gender, address, likes_chocolate_p, email)
  values
    ('Nobuko', 'Asakai', 23, 'f', '401 Boradway', 't', 'nobuko@nobody.com');

insert into best_friends
    (first_names, last_name, age, gender, address, likes_chocolate_p, email)
  values
    ('Grandma', null, 83, 'f', '1320 Dreiser Ct.', null, 'grandma@nobody.com');

create table movies (
  title 	varchar2(100),
  director 	varchar2(100),
  cast		varchar2(500),
  year		integer,
  comments 	varchar2(2000)
);

insert into movies 
    (title, director, cast, year, comments)
  values
    ('2001: Space Odyssey', 'Stanley Kubrick', 'A big space fetus', null,  'Neat! This movie had cool spaceships and a crazy computer!');

insert into movies 
    (title, director, cast, year, comments)
  values
    ('Dancer in the Dark', 'Lars von Trier', 'Bjork',2000, 'This movie was very sad.  It made me cry');

insert into movies
    (title, director, cast, year, comments)
  values
    ('Charlie"s Angel',null, 'Drew Barrymore, Bill Murray', 2000, 'This movie was very sad.  It also made me cry');



create table address_book (  
-- entry_id 	integer,
  first_names   varchar2(40),
  last_name     varchar2(40),
  title 	varchar2(40),
  birthday      date,
  gender        char(1) check (gender in ('m', 'f')),
  address       varchar2(300),
  city 		varchar2(100),
  state		varchar2(40),
  zip		varchar2(10),
  country	varchar2(100),
  email         varchar2(100),
  relation_types varchar2(400),
  primary_phone varchar2(40),
  home_phone	varchar2(40),
  work_phone	varchar2(40),
  cell_phone	varchar2(40),
  pager		varchar2(40),
  fax 		varchar2(40)
);
  

