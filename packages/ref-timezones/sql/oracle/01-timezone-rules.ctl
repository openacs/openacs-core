load data infile '[acs_root_dir]/packages/ref-timezones/sql/common/timezone-rules.dat'
into table timezone_rules
replace
fields terminated by "," optionally enclosed by "'"
(tz_id,abbrev,utc_start date "DY Mon DD HH24:MI:SS YYYY",
 utc_end date "DY Mon DD HH24:MI:SS YYYY",
 local_start date "DY Mon DD HH24:MI:SS YYYY",
 local_end date "DY Mon DD HH24:MI:SS YYYY",
 gmt_offset,
 isdst
)
