copy language_codes from '[acs_root_dir]/packages/ref-language/sql/common/languages.dat' 
[ad_decode [db_version] "7.2" "delimiters" "delimiter"] ',' 
[ad_decode [db_version] "7.2" "with null as" "null"] ''
