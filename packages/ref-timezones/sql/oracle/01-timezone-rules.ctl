load data infile '[acs_root_dir]/packages/ref-timezones/sql/common/timezone-rules.dat'
into table timezone_rules
replace
fields terminated by "," optionally enclosed by "'"
(tz_id,abbrev,utc_start date "Mon DD YYYY HH:MI:SS",
 utc_end date "Mon DD YYYY HH:MI:SS",
 local_start date "Mon DD YYYY HH:MI:SS",
 local_end date "Mon DD YYYY HH:MI:SS",
 gmt_offset,
 isdst
)
