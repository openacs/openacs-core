load data infile '[acs_root_dir]/packages/ref-language/sql/common/iso-639-1.dat'
into table language_codes
replace
fields terminated by "|" optionally enclosed by "'"
(language_id,name)
