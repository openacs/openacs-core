load data infile '[acs_root_dir]/packages/ref-language/sql/common/languages.dat'
into table language_codes
replace
fields terminated by "," optionally enclosed by "'"
(language_id,name)
