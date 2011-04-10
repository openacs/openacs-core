create or replace function number_src(text) returns text as '
declare
        v_src   alias for $1;
        v_pos   integer;
        v_ret   text default '''';
        v_tmp   text;
        v_cnt   integer default -1;
begin
        if v_src is null then 
	     return null;
        end if;

        v_tmp := v_src;
        LOOP
            v_pos := position(''\n'' in v_tmp);
            v_cnt := v_cnt + 1;

            exit when v_pos = 0;

            if v_cnt != 0 then
              v_ret := v_ret || to_char(v_cnt,''9999'') || '':'' || substr(v_tmp,1,v_pos);
            end if;
            v_tmp := substr(v_tmp,v_pos + 1);
        end LOOP;

        return v_ret || to_char(v_cnt,''9999'') || '':'' || v_tmp;

end;' language 'plpgsql' immutable strict;

create or replace function get_func_definition (varchar,oidvector) returns text as '
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
               (select typname from pg_type where oid = p.prorettype::integer)
          into v_args, v_nargs, v_src, v_rettype
          from pg_proc p 
         where proname = fname::name
           and proargtypes = args;

         v_funcdef := v_funcdef || ''
create or replace function '' || fname || ''('';

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
              where oid = v_one_arg::integer;
             v_funcdef := v_funcdef || v_one_type;
         end loop;
         v_funcdef := v_funcdef || '') returns '' || v_rettype || '' as \\\'\\n'' || v_src || ''\\\' language \\\'plpgsql\\\';'';

        return v_funcdef;

end;' language 'plpgsql' stable strict;
