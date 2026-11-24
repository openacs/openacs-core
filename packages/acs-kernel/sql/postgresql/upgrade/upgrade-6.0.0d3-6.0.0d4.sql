-- Add the input name to the legacy signature without dropping the function.
do $$
declare
    function_oid oid := to_regprocedure('util__get_primary_keys(text)');
    definition text;
begin
    select pg_get_functiondef(oid) into definition
      from pg_proc
     where oid = function_oid and proargnames is null;

    if found then
        execute regexp_replace(definition, '([(])text([)])', '(arg_table_name text)');
    end if;
end;
$$;
