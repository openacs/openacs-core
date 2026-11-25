-- Drop the legacy constructor whose creation_ip argument is an integer.
-- Handle both the original name and the name used during retirement.
begin;

drop function if exists public.acs_reference__new(
    integer, varchar, boolean, varchar, timestamptz, varchar, varchar,
    timestamptz, timestamptz, integer, integer, varchar, varchar,
    integer, varchar, integer
) restrict;

drop function if exists public.acs_reference__new_retired(
    integer, varchar, boolean, varchar, timestamptz, varchar, varchar,
    timestamptz, timestamptz, integer, integer, varchar, varchar,
    integer, varchar, integer
) restrict;

commit;
