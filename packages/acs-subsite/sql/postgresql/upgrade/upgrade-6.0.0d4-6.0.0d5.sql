-- Restore input names on existing generated constructors. Use arg_ names
-- so that existing p_ aliases in the function body do not need to change.
do $$
declare
    constructor record;
    definition text;
begin
    for constructor in
        select p.oid, n.nspname, p.proname,
               string_agg(format('%I %s', 'arg_' || lower(a.arg_name),
                                 format_type(arg.type_oid, null)),
                          ', ' order by arg.position) as signature
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          cross join lateral unnest(p.proargtypes::oid[]) with ordinality as arg(type_oid, position)
          join acs_function_args a
            on a.function = upper(p.proname) and a.arg_seq = arg.position
         where p.proargnames is null
           and p.pronargdefaults = 0
           and pg_function_is_visible(p.oid)
           and exists (
               select 1 from acs_object_types t
                where t.dynamic_p = 't' and p.proname = lower(t.package_name) || '__new'
           )
         group by p.oid, n.nspname, p.proname
        having count(*) = p.pronargs
           and count(*) = (select count(*) from acs_function_args
                            where function = upper(p.proname))
    loop
        definition := pg_get_functiondef(constructor.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       constructor.nspname, constructor.proname, constructor.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;

-- An old installation can retain instructor_rel metadata after its type
-- and constructor have both been removed.
delete from acs_function_args
 where function = 'INSTRUCTOR_REL__NEW'
   and not exists (select 1 from acs_object_types
                    where lower(package_name) = 'instructor_rel')
   and not exists (select 1 from pg_proc where proname = 'instructor_rel__new'
                    and pg_function_is_visible(oid));
