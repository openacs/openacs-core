load data infile '[acs_root_dir]/packages/ref-countries/sql/common/countries.dat'
into table countries
replace
fields terminated by ";" optionally enclosed by "'"
(default_name,iso)
