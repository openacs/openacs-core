
--
-- Create The Tree Package
--
-- @author ben@openforce
-- @creation-date 2002-05-17
-- @version $Id$
--
-- This does funky sortkey stuff in Oracle,
-- similar to DonB's PG varbit stuff, but without varbits
-- because Oracle has no varbits.
--
-- This scheme is usable in PG, too, but probably not as
-- efficient as Don's varbit scheme. So we use it only in Oracle
--

create or replace package tree
as

    function hex_to_int (
        p_hex                           in raw
    ) return integer;

    function int_to_hex (
        p_int                           in integer
    ) return raw;

    function increment_key (
        tree_key                        in raw
    ) return raw;

    function next_key (
        parent_key                      in raw,
        max_child_key                   in raw
    ) return raw;

    function left (
        raw_key                         in raw
    ) return raw;

    function right (
        raw_key                         in raw
    ) return raw;

    function ancestor_key (
        raw_key                         in raw,
        tree_level                      in integer
    ) return raw;

    function tree_level (
        raw_key                         in raw
    ) return integer;

    function ancestor_p (
        ancestor_key                    in raw,
        child_key                       in raw
    ) return char;

end tree;
/
show errors

create or replace package body tree
as

    function hex_to_int (
        p_hex                           in raw
    ) return integer
    is
        v_int                           integer := 0;
        v_current_pow                   integer := 1;
        v_current_pos                   integer := length(p_hex);
        v_current_char                  integer;
    begin
        while v_current_pos > 0 loop
            v_current_char:= ascii(upper(substr(p_hex, v_current_pos, 1)));

            if (v_current_char between 48 and 57)
            then
                -- between 1 and 9
                v_int:= v_int + (v_current_pow * (v_current_char - 48));
            else
                -- between A and F
                v_int:= v_int + (v_current_pow * (v_current_char - 55));
            end if;

            -- change things
            v_current_pow:= v_current_pow * 16;
            v_current_pos:= v_current_pos - 1;
        end loop;

        return v_int;
    end hex_to_int;

    function int_to_hex (
        p_int                           in integer
    ) return raw
    is
        v_hex                           raw(9) := '';
        v_current_pow                   integer := 4294967296;
        v_remainder                     integer := p_int;
        v_current_div                   integer;
    begin
        while v_current_pow >= 1 loop
            v_current_div:= floor(v_remainder/v_current_pow);

            -- we're not prepending 0's
            if v_current_div > 0 or length(v_hex) > 0 then
                -- 0-9 or A-F
                if v_current_div between 0 and 9
                then v_hex:= v_hex || chr(48 + v_current_div);
                else v_hex:= v_hex || chr(55 + v_current_div);
                end if;
            end if;

            -- adjust for next round
            v_remainder:= mod(v_remainder, v_current_pow);
            v_current_pow:= v_current_pow / 16;
        end loop;

        return v_hex;
    end int_to_hex;

    function increment_key (
        tree_key                        in raw
    ) return raw
    is
    begin
        if tree_key is null
        then
            return '000000';
        else
            return (lpad(int_to_hex(hex_to_int(tree_key) + 1), 6, '0'));
        end if;
    end increment_key;

    function next_key (
        parent_key                      in raw,
        max_child_key                   in raw
    ) return raw
    is
    begin
        return parent_key || increment_key(max_child_key);
    end next_key;

    function left (
        raw_key                         in raw
    ) return raw
    is
    begin
        return raw_key || '000000';
    end left;

    function right (
        raw_key                         in raw
    ) return raw
    is
    begin
        return raw_key || 'ffffff';
    end right;

    function ancestor_key (
        raw_key                         in raw,
        tree_level                      in integer
    ) return raw
    is
    begin
        return substr(raw_key, 1, 6 * tree_level);
    end ancestor_key;

    function tree_level (
        raw_key                         in raw
    ) return integer
    is
    begin
        return length(raw_key) / 6;
    end tree_level;

    function parent_key (
        raw_key                         in raw
    ) return raw
    is
    begin
        return substr(raw_key, 1, 6 * tree_level(raw_key) - 6);
    end parent_key;

    function ancestor_p (
        ancestor_key                    in raw,
        child_key                       in raw
    ) return char
    is
    begin
        if substr(child_key, 1, length(ancestor_key)) = ancestor_key
        then return 't';
        else return 'f';
        end if;
    end ancestor_p;

end tree;
/
show errors
