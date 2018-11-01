-- for PostgreSQL 7.4 the || op needs an explicit cast.

create or replace function tree_left(varbit) returns varbit as '

-- Create a key less than or equal to that of any child of the
-- current key.

declare
  key      alias for $1;
begin
  if key is null then
    return ''X00''::varbit;
  else
    return key || ''X00''::varbit;
  end if;
end;' language 'plpgsql' with(iscachable);

create or replace function tree_right(varbit) returns varbit as '

-- Create a key greater or equal to that of any child of the current key.
-- Used in BETWEEN expressions to select the subtree rooted at the given
-- key. 

declare
  key      alias for $1;
begin
  if key is null then
    return ''XFFFFFFFF''::varbit;
  else
    return key || ''XFFFFFFFF''::varbit;
  end if;
end;' language 'plpgsql' with(iscachable);
