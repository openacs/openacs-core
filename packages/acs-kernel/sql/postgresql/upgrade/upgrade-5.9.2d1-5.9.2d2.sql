-- PG11 compatibility
--
-- procedure trigger_type/1
--
CREATE OR REPLACE FUNCTION trigger_type(
   tgtype integer
) RETURNS varchar AS $$
DECLARE
  description       varchar;
  sep               varchar;
BEGIN

 if (tgtype & 2) > 0 then
    description := 'BEFORE ';
 else 
    description := 'AFTER ';
 end if;

 sep := '';

 if (tgtype & 4) > 0 then
    description := description || 'INSERT ';
    sep := 'OR ';
 end if;

 if (tgtype & 8) > 0 then
    description := description || sep || 'DELETE ';
    sep := 'OR ';
 end if;

 if (tgtype & 16) > 0 then
    description := description || sep || 'UPDATE ';
    sep := 'OR ';
 end if;

 if (tgtype & 1) > 0 then
    description := description || 'FOR EACH ROW';
 else
    description := description || 'STATEMENT';
 end if;

 return description;

END;
$$ LANGUAGE plpgsql IMMUTABLE;
