-- Keep the deployed argument name, which can differ between fresh
-- installations and databases repaired by the preceding upgrade.
do $$
declare
    definition text := pg_get_functiondef('content_template__delete(integer)'::regprocedure);
    corrected text;
begin
    corrected := regexp_replace(definition, '(perform[[:space:]]+)content_template__delete([[:space:]]*[(])',
                                '\1content_template__del\2', 'i');
    if corrected <> definition then
        execute corrected;
    end if;
end;
$$;
