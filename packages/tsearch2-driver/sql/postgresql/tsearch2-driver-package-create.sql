--
-- procedure ts2_to_tsvector/2
--
CREATE OR REPLACE FUNCTION ts2_to_tsvector ( 
       ts2_cfg varchar, 
       ts2_txt varchar 
) RETURNS varchar AS $$
DECLARE
ts2_result varchar;
BEGIN
	perform set_curcfg(ts2_cfg);
	select to_tsvector(ts2_cfg,ts2_txt) into ts2_result;
	return ts2_result;
END;
$$ language plpgsql;

--
-- procedure ts2_to_tsquery/2
--
CREATE OR REPLACE FUNCTION ts2_to_tsquery ( 
       ts2_cfg varchar, 
       ts2_txt varchar 
) RETURNS tsquery AS $$
DECLARE
ts2_result tsquery;
BEGIN
	perform set_curcfg(ts2_cfg);
	select 1 into ts2_result;
	select to_tsquery(ts2_cfg,ts2_txt) into ts2_result;
	return ts2_result;
END;
$$ LANGUAGE plpgsql;

