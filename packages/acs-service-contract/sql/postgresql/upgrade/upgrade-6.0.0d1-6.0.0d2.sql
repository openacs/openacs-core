-- Name both documented overloads so only the one matching the
-- registered argument names is eligible for the dispatcher.
-- Prefix names to avoid collisions with the aliases in legacy bodies.
do $$
declare
    target record;
    definition text;
begin
    for target in
        with expected(function_name, input_types, input_names, companion_types, registered_names) as (
            values
            ('acs_sc_binding__new', 'integer,integer', 'contract_id,impl_id', 'varchar,varchar', array['contract_name,impl_name']),
            ('acs_sc_binding__new', 'varchar,varchar', 'contract_name,impl_name', 'integer,integer', array['contract_name,impl_name']),
            ('acs_sc_binding__delete', 'integer,integer', 'contract_id,impl_id', 'varchar,varchar', array['contract_name,impl_name']),
            ('acs_sc_binding__delete', 'varchar,varchar', 'contract_name,impl_name', 'integer,integer', array['contract_name,impl_name']),
            ('acs_sc_contract__delete', 'integer', 'contract_id', 'varchar', array['contract_id', 'contract_name']),
            ('acs_sc_contract__delete', 'varchar', 'contract_name', 'integer', array['contract_id', 'contract_name']),
            ('acs_sc_msg_type__delete', 'integer', 'msg_type_id', 'varchar', array['msg_type_id', 'msg_type_name']),
            ('acs_sc_msg_type__delete', 'varchar', 'msg_type_name', 'integer', array['msg_type_id', 'msg_type_name'])
        )
        select p.oid, n.nspname, p.proname, arguments.signature
          from expected e
          join pg_proc p on p.oid = to_regprocedure(
              format('%I.%I(%s)', current_schema(), e.function_name, e.input_types))
          join pg_namespace n on n.oid = p.pronamespace
          cross join lateral (
              select string_agg(
                         format('%I %s', 'arg_' || a.arg_name, format_type(a.type_oid, null)),
                         ', ' order by a.position) as signature
                from unnest(p.proargtypes::oid[], string_to_array(e.input_names, ','))
                     with ordinality as a(type_oid, arg_name, position)
          ) arguments
         where p.prokind = 'f'
           and p.proargnames is null
           and p.proargmodes is null
           and p.pronargdefaults = 0
           and p.pronargs = cardinality(string_to_array(e.input_names, ','))
           and p.pronargs = (
               select count(*) from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and not exists (
               select 1 from acs_function_args a
                where a.function = upper(e.function_name)
                  and (a.arg_seq < 1 or a.arg_seq > p.pronargs)
           )
           and (
               select string_agg(lower(a.arg_name), ',' order by a.arg_seq)
                 from acs_function_args a
                where a.function = upper(e.function_name)
           ) = any(e.registered_names)
           and not exists (
               select 1 from pg_proc other
                where other.proname = p.proname
                  and other.pronargs = p.pronargs
                  and other.oid <> p.oid
                  and other.oid is distinct from to_regprocedure(
                      format('%I.%I(%s)', n.nspname, e.function_name, e.companion_types))
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
