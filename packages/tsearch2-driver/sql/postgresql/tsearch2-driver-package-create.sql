create or replace function ts2_to_tsvector ( varchar, varchar ) returns varchar as '
declare
ts2_cfg alias for $1;
ts2_txt alias for $2;
ts2_result varchar;
begin

perform set_curcfg(ts2_cfg);
select to_tsvector(ts2_cfg,ts2_txt) into ts2_result;
return ts2_result;
end;' language 'plpgsql';

create or replace function ts2_to_tsquery ( varchar, varchar ) returns tsquery as '
declare
ts2_cfg alias for $1;
ts2_txt alias for $2;
ts2_result tsquery;
begin
perform set_curcfg(ts2_cfg);
select 1 into ts2_result;
select to_tsquery(ts2_cfg,ts2_txt) into ts2_result;
return ts2_result;
end;' language 'plpgsql';

