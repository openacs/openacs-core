load data infile '[acs_root_dir]/packages/ref-timezones/sql/common/timezones.dat'
into table timezones
replace
fields terminated by "," optionally enclosed by "'"
(tz_id,tz,gmt_offset)
