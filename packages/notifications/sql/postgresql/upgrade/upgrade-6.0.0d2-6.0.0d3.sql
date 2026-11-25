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
            ('notification__delete', 'integer', 'notification_id'),
            ('notification__new', 'integer,integer,integer,timestamptz,integer,integer,varchar,text,text,text,timestamptz,integer,varchar,integer', 'notification_id,type_id,object_id,notif_date,response_id,notif_user,notif_subject,notif_text,notif_html,file_ids,creation_date,creation_user,creation_ip,context_id'),
            ('notification_delivery_method__delete', 'integer', 'delivery_method_id'),
            ('notification_delivery_method__new', 'integer,integer,varchar,varchar,timestamptz,integer,varchar,integer', 'delivery_method_id,sc_impl_id,short_name,pretty_name,creation_date,creation_user,creation_ip,context_id'),
            ('notification_interval__delete', 'integer', 'interval_id'),
            ('notification_interval__new', 'integer,varchar,integer,timestamptz,integer,varchar,integer', 'interval_id,name,n_seconds,creation_date,creation_user,creation_ip,context_id'),
            ('notification_reply__delete', 'integer', 'reply_id'),
            ('notification_reply__new', 'integer,integer,integer,integer,varchar,text,timestamptz,timestamptz,integer,varchar,integer', 'reply_id,object_id,type_id,from_user,subject,content,reply_date,creation_date,creation_user,creation_ip,context_id'),
            ('notification_request__delete', 'integer', 'request_id'),
            ('notification_request__delete_all', 'integer', 'object_id'),
            ('notification_request__delete_all_for_user', 'integer', 'user_id'),
            ('notification_request__new', 'integer,varchar,integer,integer,integer,integer,integer,varchar,boolean,timestamptz,integer,varchar,integer', 'request_id,object_type,type_id,user_id,object_id,interval_id,delivery_method_id,format,dynamic_p,creation_date,creation_user,creation_ip,context_id'),
            ('notification_type__delete', 'integer', 'type_id'),
            ('notification_type__new', 'integer,integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer', 'type_id,sc_impl_id,short_name,pretty_name,description,creation_date,creation_user,creation_ip,context_id')
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
