-- Add names only to signatures verified against the current install SQL.
-- Prefix names to avoid collisions with the aliases in legacy bodies.
do $$
declare
    target record;
    definition text;
begin
    for target in
        with expected(function_name, input_types, input_names) as (
            values
            ('acs_sc_binding__exists_p', 'varchar,varchar', 'contract_name,impl_name'),
            ('acs_sc_contract__get_id', 'varchar', 'contract_name'),
            ('acs_sc_contract__get_name', 'integer', 'contract_id'),
            ('acs_sc_contract__new', 'varchar,text', 'contract_name,contract_desc'),
            ('acs_sc_impl_alias__delete', 'varchar,varchar,varchar', 'impl_contract_name,impl_name,impl_operation_name'),
            ('acs_sc_impl_alias__new', 'varchar,varchar,varchar,varchar,varchar', 'impl_contract_name,impl_name,impl_operation_name,impl_alias,impl_pl'),
            ('acs_sc_impl__get_id', 'varchar,varchar', 'impl_contract_name,impl_name'),
            ('acs_sc_impl__get_name', 'integer', 'impl_id'),
            ('acs_sc_impl__new', 'varchar,varchar,varchar,varchar', 'impl_contract_name,impl_name,impl_pretty_name,impl_owner_name'),
            ('acs_sc_msg_type__get_id', 'varchar', 'msg_type_name'),
            ('acs_sc_msg_type__get_name', 'integer', 'msg_type_id'),
            ('acs_sc_msg_type__new', 'varchar,varchar', 'msg_type_name,msg_type_spec'),
            ('acs_sc_msg_type__new_element', 'varchar,varchar,varchar,boolean,integer', 'msg_type_name,element_name,element_msg_type_name,element_msg_type_isset_p,element_pos'),
            ('acs_sc_msg_type__parse_spec', 'varchar,varchar', 'msg_type_name,msg_type_spec'),
            ('acs_sc_operation__delete', 'integer', 'operation_id'),
            ('acs_sc_operation__get_id', 'varchar,varchar', 'contract_name,operation_name'),
            ('acs_sc_operation__new', 'varchar,varchar,text,boolean,integer,varchar,varchar', 'contract_name,operation_name,operation_desc,operation_iscachable_p,operation_nargs,operation_inputtype,operation_outputtype')
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
           and e.input_names = (
               select string_agg(lower(a.arg_name), ',' order by a.arg_seq)
                 from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and not exists (
               select 1 from pg_proc other
                where other.proname = p.proname
                  and other.pronargs = p.pronargs
                  and other.oid <> p.oid
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
