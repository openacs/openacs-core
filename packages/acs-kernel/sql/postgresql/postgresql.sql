create view dual as select now() as sysdate;

-- used to support anonymous plsql blocks in the db_plsql function call in tcl.
create sequence t_anon_func_seq;
create view anon_func_seq as 
select nextval('t_anon_func_seq') as nextval;

create function instr(varchar,char,integer,integer) returns integer as '
declare
        str             alias for $1;
        pat             alias for $2;
        dir             alias for $3;
        cnt             alias for $4;
        v_len           integer;
        v_i             integer;
        v_c             char;
        v_cnt           integer;
        v_inc           integer;
begin
        v_len := length(str);
        v_cnt := 0;
        
        if dir < 0 then
           v_inc := \-1;
           v_i   := v_len + 1 - dir;
        else 
           v_inc := 1;
           v_i   := dir;
        end if;
           
        while v_i > 0 and v_i <= v_len LOOP
          v_c := substr(str,v_i,1);
          if v_c::char = pat::char then 
            v_cnt := v_cnt + 1;
            if v_cnt = cnt then 
              return v_i;
            end if;
          end if;
          v_i := v_i + v_inc;
        end loop;

        return 0;

end;' language 'plpgsql';


create function instr(varchar,char,integer) returns integer as '
declare
        str             alias for $1;
        pat             alias for $2;
        dir             alias for $3;
begin
        return instr(str,pat,dir,1);
end;' language 'plpgsql';


create function instr(varchar,char) returns integer as '
declare
        str             alias for $1;
        pat             alias for $2;
begin
        return instr(str,pat,1,1);
end;' language 'plpgsql';


-- Splits string on requested character. Returns requested element
-- (1-based)

create function split(varchar,char,integer)
returns varchar as '
declare
  p_string		alias for $1;
  p_split_char		alias for $2;
  p_element		alias for $3;

  v_left_split		integer;
  v_right_split		integer;
  v_len			integer;
begin
  v_len = length(p_string);
  if v_len = 0 or p_string is null or p_element <= 0 then
    return NULL;
  end if;
  if p_element = 1 then
    v_left_split := 0;
  else
    v_left_split := instr(p_string, p_split_char, 1, p_element-1);
  end if;
  v_right_split := instr(p_string, p_split_char, 1, p_element);
  if v_right_split = 0 then
    v_right_split = v_len + 1;
  end if;
  if v_left_split = 0 and v_right_split = v_len+1 and p_element <> 1 then
    return null;
  end if;
  return substr(p_string, v_left_split+1, (v_right_split - v_left_split - 1));
end;' language 'plpgsql';


create function get_func_drop_command (varchar) returns varchar as '
declare
        fname           alias for $1;
        nargs           integer default 0;
        v_pos           integer;
        v_funcdef       text;
        v_args          varchar;
        v_one_arg       varchar;
        v_one_type      varchar;
        v_nargs         integer;
begin
        v_funcdef := ''drop function '' || fname || ''('';

        select proargtypes, pronargs
          into v_args, v_nargs
          from pg_proc 
         where proname = fname::name;

        v_pos := position('' '' in v_args);
        
        while nargs < v_nargs loop
              nargs := nargs + 1;
              if nargs = v_nargs then 
                 v_one_arg := v_args;
                 v_args    := '''';
              else
                 v_one_arg := substr(v_args, 1, v_pos \- 1);
                 v_args    := substr(v_args, v_pos + 1);
                 v_pos     := position('' '' in v_args);            
              end if;
              select case when nargs = 1 
                            then typname 
                            else '','' || typname 
                          end into v_one_type 
                from pg_type 
               where oid = v_one_arg;
              v_funcdef := v_funcdef || v_one_type;            
        end loop;
        v_funcdef := v_funcdef || '')'';

        return v_funcdef;

end;' language 'plpgsql';

create function drop_package (varchar) returns varchar as '
declare
       package_name      alias for $1;
       v_rec             record;
       v_drop_cmd        varchar;
       v_pkg_name        varchar;
begin
        raise NOTICE ''DROP PACKAGE: %'', package_name;
        v_pkg_name := package_name || ''\\\\_\\\\_'' || ''%'';

        for v_rec in select proname 
                       from pg_proc 
                      where proname like v_pkg_name 
                   order by proname 
        LOOP
            raise NOTICE ''DROPPING FUNCTION: %'', v_rec.proname;
            v_drop_cmd := get_func_drop_command (v_rec.proname);
            EXECUTE v_drop_cmd;
        end loop;

        if NOT FOUND then 
          raise NOTICE ''PACKAGE: % NOT FOUND'', package_name;
        else
          raise NOTICE ''PACKAGE: %: DROPPED'', package_name;
        end if;
        
        return null;

end;' language 'plpgsql';

create function number_src(text) returns text as '
declare
        v_src   alias for $1;
        v_pos   integer;
        v_ret   text default '''';
        v_tmp   text;
        v_cnt   integer default -1;
begin
        v_tmp := v_src;
        LOOP
            v_pos := position(''\n'' in v_tmp);
            v_cnt := v_cnt + 1;

            exit when v_pos = 0;

            if v_cnt != 0 then
              v_ret := v_ret || rpad(v_cnt,10) || substr(v_tmp,1,v_pos);
            end if;
            v_tmp := substr(v_tmp,v_pos + 1);
        end LOOP;

        return v_ret || rpad(v_cnt,10) || v_tmp;

end;' language 'plpgsql';

create function get_func_definition (varchar,oidvector) returns text as '
declare
        fname           alias for $1;
        args            alias for $2;
        nargs           integer default 0;
        v_pos           integer;
        v_funcdef       text default '''';
        v_args          varchar;
        v_one_arg       varchar;
        v_one_type      varchar;
        v_nargs         integer;
        v_src           text;
        v_rettype       varchar;
begin
        select proargtypes, pronargs, number_src(prosrc), 
               (select typname from pg_type where oid = p.prorettype)
          into v_args, v_nargs, v_src, v_rettype
          from pg_proc p 
         where proname = fname::name
           and proargtypes = args;
        
         v_funcdef := v_funcdef || ''
create function '' || fname || ''('';
        
         v_pos := position('' '' in v_args);
        
         while nargs < v_nargs loop
             nargs := nargs + 1;
             if nargs = v_nargs then 
                 v_one_arg := v_args;
                 v_args    := '''';
             else
                 v_one_arg := substr(v_args, 1, v_pos \- 1);
                 v_args    := substr(v_args, v_pos + 1);
                 v_pos     := position('' '' in v_args);            
             end if;
             select case when nargs = 1 
                           then typname 
                           else '','' || typname 
                         end into v_one_type 
               from pg_type 
              where oid = v_one_arg;
             v_funcdef := v_funcdef || v_one_type;            
         end loop;
         v_funcdef := v_funcdef || '') returns '' || v_rettype || '' as \\\'\\n'' || v_src || ''\\\' language \\\'plpgsql\\\';'';
        
        return v_funcdef;

end;' language 'plpgsql';

create function get_func_header(varchar,oidvector) returns text as '
declare
        fname   alias for $1;
        args    alias for $2;
        v_src   text;
        pos     integer;
begin
        v_src := get_func_definition(fname,args);
        pos := position(''begin'' in lower(v_src));

        return substr(v_src, 1, pos + 4);

end;' language 'plpgsql';

create view acs_func_defs as 
select get_func_definition(proname,proargtypes) as definition, 
       proname as fname 
  from pg_proc;

create view acs_func_headers as 
select get_func_header(proname,proargtypes) as definition, 
       proname as fname 
  from pg_proc;

-- tree query support, m-vgID method.

CREATE TABLE tree_encodings (
        deci int primary key,
	code char(1) 
);

create index tree_encode_idx on tree_encodings(code);


copy tree_encodings from stdin using delimiters '/' ;
0/0
1/1
2/2
3/3
4/4
5/5
6/6
7/7
8/8
9/9
10/:
11/;
12/A
13/B
14/C
15/D
16/E
17/F
18/G
19/H
20/I
21/J
22/K
23/L
24/M
25/N
26/O
27/P
28/Q
29/R
30/S
31/T
32/U
33/V
34/W
35/X
36/Y
37/Z
38/a
39/b
40/c
41/d
42/e
43/f
44/g
45/h
46/i
47/j
48/k
49/l
50/m
51/n
52/o
53/p
54/q
55/r
56/s
57/t
58/u
59/v
60/w
61/x
62/y
63/z
64/¡
65/¢
66/£
67/¤
68/¥
69/¦
70/§
71/¨
72/©
73/ª
74/«
75/¬
76/­
77/®
78/¯
79/°
80/±
81/²
82/³
83/´
84/µ
85/¶
86/·
87/¸
88/¹
89/º
90/»
91/¼
92/½
93/¾
94/¿
95/À
96/Á
97/Â
98/Ã
99/Ä
100/Å
101/Æ
102/Ç
103/È
104/É
105/Ê
106/Ë
107/Ì
108/Í
109/Î
110/Ï
111/Ð
112/Ñ
113/Ò
114/Ó
115/Ô
116/Õ
117/Ö
118/×
119/Ø
120/Ù
121/Ú
122/Û
123/Ü
124/Ý
125/Þ
126/ß
127/à
128/á
129/â
130/ã
131/ä
132/å
133/æ
134/ç
135/è
136/é
137/ê
138/ë
139/ì
140/í
141/î
142/ï
143/ð
144/ñ
145/ò
146/ó
147/ô
148/õ
149/ö
150/÷
151/ø
152/ù
153/ú
154/û
155/ü
156/ý
157/þ
158/ÿ
\.

create function tree_default_encoding_base() returns integer as '
begin
        return 159;
end;' language 'plpgsql';

create function tree_next_key(varchar) returns varchar as '
declare
       skey     alias for $1;
       pos      integer;        
       stop     boolean default ''f'';
       carry    boolean default ''t'';
       nkey     varchar default '''';
       base     integer;
       ch       char(1);
begin
        base := tree_default_encoding_base();

        if skey is null then

           return ''00'';

        else
           pos := length(skey);
           LOOP               
               ch := substr(skey,pos,1);
               if carry then 
                   select code::varchar || nkey,
                          code = ''0'' 
                     into nkey, carry
                     from tree_encodings 
                    where deci = (select (deci + 1) % base
                                    from tree_encodings
                                   where code = ch);
               else
                   nkey := ch::varchar || nkey;
               end if;
               pos := pos - 1;               
               select substr(skey,pos - 1,1) = ''/'' into stop;

               exit when stop;

           END LOOP;
           if carry then 
              nkey := ''0'' || nkey;
           end if;
        end if;

        select code::varchar || nkey into nkey
          from tree_encodings 
         where deci = length(nkey) - 1;

        return nkey;

end;' language 'plpgsql';


create function tree_level(varchar) returns integer as '
declare
        inkey     alias for $1;
        cnt       integer default 0;
begin
        for i in 1..length(inkey) LOOP
            if substr(inkey,i,1) = ''/'' then
               cnt := cnt + 1;
            end if;
        end LOOP;

        return cnt;

end;' language 'plpgsql';


-- PG substitute for Oracle user_tab_columns view

create view user_tab_columns as
  select upper(c.relname) as table_name,
	 upper(a.attname) as column_name,
	 upper(t.typname) as data_type
    from pg_class c, pg_attribute a, pg_type t
   where c.oid = a.attrelid
     and a.atttypid = t.oid
     and a.attnum > 0;

-- PG substitute for Oracle user_col_comments view

create view user_col_comments as
  select upper(c.relname) as table_name,
	 upper(a.attname) as column_name,
	 d.description as comments
    from pg_class c,
         pg_attribute a
           left outer join pg_description d on (a.oid = d.objoid)
   where c.oid = a.attrelid
     and a.attnum > 0;

-- PG substitute for Oracle user_col_comments view

create view user_tab_comments as
  select upper(c.relname) as table_name,
	 case
	   when c.relkind = 'r' then 'TABLE'
	   when c.relkind = 'v' then 'VIEW'
	   else c.relkind::text
	 end as table_type,
	 d.description as comments
    from pg_class c
           left outer join pg_description d on (c.oid = d.objoid);

-- Table for storing PL/PGSQL function arguments

create table acs_function_args (
       function              varchar(100) not null,
       arg_seq		     integer not null,
       arg_name		     varchar(100),
       arg_default	     varchar(100),
       constraint acs_function_args_pk
       primary key (function, arg_seq),
       constraint acs_function_args_un
       unique (function, arg_name)
);


-- Add entries to acs_function_args for one function
-- Usage: select define_function_args('function_name','arg1,arg2;default,arg3,arg4;default')

create function define_function_args(varchar,varchar)
returns integer as '
declare
  p_function		alias for $1;
  p_arg_list		alias for $2;

  v_arg_seq		integer default 1;
  v_arg_name		varchar;
  v_arg_default		varchar;
  v_elem		varchar;
  v_pos			integer;
begin
  delete from acs_function_args where function = upper(p_function);

  v_elem = split(p_arg_list, '','', v_arg_seq);
  while v_elem is not null loop
    
    v_pos = instr(v_elem, '';'', 1, 1);
    if v_pos > 0 then
      v_arg_name := substr(v_elem, 1, v_pos-1);
      v_arg_default := substr(v_elem, v_pos+1, length(v_elem) - v_pos);
    else
      v_arg_name := v_elem;
      v_arg_default := NULL;
    end if;

    insert into acs_function_args (function, arg_seq, arg_name, arg_default)
	   values (upper(p_function), v_arg_seq, upper(v_arg_name), v_arg_default);

    v_arg_seq := v_arg_seq + 1;
    v_elem = split(p_arg_list, '','', v_arg_seq);
  end loop;
    
  return 1;
end;' language 'plpgsql';

