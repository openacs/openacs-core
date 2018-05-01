--
-- Replace obsolete funktion bitfromint4() by cast
---
-- ... but keep emulation function still around in case somebodes uses
-- this still....
--


--
-- procedure int_to_tree_key/1
--
CREATE OR REPLACE FUNCTION int_to_tree_key(
   p_intkey integer
) RETURNS varbit AS $$
-- Convert an integer into the bit string format used to store
-- tree sort keys.   Using 4 bytes for the long keys requires
-- using -2^31 rather than 2^31 to avoid a twos-complement 
-- "integer out of range" error in PG - if for some reason you
-- want to use a smaller value use positive powers of two!

-- There was an "out of range" check in here when I was using 15
-- bit long keys but the only check that does anything with the long
-- keys is to check for negative numbers.
DECLARE
BEGIN
  if p_intkey < 0 then
    raise exception 'int_to_tree_key: key must be a positive integer';
  end if;

  if p_intkey < 128 then
    return substring(p_intkey::bit(32), 25, 8);
  else
    return substring((cast (-2^31 + p_intkey as int4))::bit(32), 1, 32);
  end if;

END;
$$ LANGUAGE plpgsql immutable strict;

