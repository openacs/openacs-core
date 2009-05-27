# Purpose: Show a summary of files within a package. This includes metrics
#          like '# of procs', '# of lines'
#
# param: package_key (such as acs-admin or lars-blogger)

apm::metrics -package_key $package_key \
    -file_type tcl_procs \
    -array tcl_metrics

apm::metrics -package_key $package_key \
    -file_type test_procs \
    -array test_metrics

apm::metrics -package_key $package_key \
    -file_type documentation \
    -array doc_metrics

apm::metrics -package_key $package_key \
    -file_type include_page \
    -array lib_metrics

apm::metrics -package_key $package_key \
    -file_type content_page \
    -array adp_metrics

apm::metrics -package_key $package_key \
    -file_type data_model_pg \
    -array pg_metrics

apm::metrics -package_key $package_key \
    -file_type data_model_ora \
    -array ora_metrics

