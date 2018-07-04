
DO $$
BEGIN
   update acs_datatypes set
      database_type = 'boolean'
    where datatype = 'boolean';
END$$;
