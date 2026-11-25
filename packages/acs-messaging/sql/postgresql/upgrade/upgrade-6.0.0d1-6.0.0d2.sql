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
            ('acs_message__delete', 'integer', 'message_id'),
            ('acs_message__delete_extlink', 'integer', 'extlink_id'),
            ('acs_message__delete_file', 'integer', 'file_id'),
            ('acs_message__delete_image', 'integer', 'image_id'),
            ('acs_message__edit_extlink', 'integer,varchar,varchar,text', 'extlink_id,url,label,description'),
            ('acs_message__edit_file', 'integer,varchar,text,varchar,integer,timestamptz,integer,varchar,boolean', 'file_id,title,description,mime_type,data,creation_date,creation_user,creation_ip,is_live'),
            ('acs_message__edit_image', 'integer,varchar,text,varchar,integer,integer,integer,timestamptz,integer,varchar,boolean', 'image_id,title,description,mime_type,data,width,height,creation_date,creation_user,creation_ip,is_live'),
            ('acs_message__first_ancestor', 'integer', 'message_id'),
            ('acs_message__message_p', 'integer', 'message_id'),
            ('acs_message__name', 'integer', 'message_id'),
            ('acs_message_get_tree_sortkey', 'integer', 'message_id'),
            ('acs_message__send', 'integer,integer,integer,timestamptz', 'message_id,recipient_id,grouping_id,wait_until'),
            ('acs_message__send', 'integer,varchar,integer,timestamptz', 'message_id,to_address,grouping_id,wait_until')
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
           and replace(e.input_names, ',to_address,', ',recipient_id,') = (
               select string_agg(lower(a.arg_name), ',' order by a.arg_seq)
                 from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and not exists (
               select 1 from pg_proc other
                where other.proname = p.proname
                  and other.pronargs = p.pronargs
                  and other.oid <> p.oid
                  -- Both documented send overloads have the same arity.
                  -- Only the recipient-ID overload matches dispatcher metadata.
                  and not (
                      e.function_name = 'acs_message__send'
                      and other.pronamespace = p.pronamespace
                      and other.oid = to_regprocedure(format(
                          '%I.acs_message__send(%s)', n.nspname,
                          case when e.input_types = 'integer,integer,integer,timestamptz'
                               then 'integer,varchar,integer,timestamptz'
                               else 'integer,integer,integer,timestamptz'
                          end))
                  )
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
