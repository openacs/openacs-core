load data infile '[acs_root_dir]/packages/ref-timezones/sql/common/timezones.csv'
into table timezones
replace
fields terminated by "," optionally enclosed by "'"
(tz_id,tz,gmt_offset)
