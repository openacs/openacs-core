
delete from timezones;
\copy timezones from '[acs_root_dir]/packages/ref-timezones/sql/common/timezones.dat' delimiter ',' null as ''
\copy timezone_rules from '[acs_root_dir]/packages/ref-timezones/sql/common/timezone-rules.dat' delimiter ',' null as ''
