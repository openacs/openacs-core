ad_page_contract {

    @author Neophytos Demetriou

} {
    contract_id:naturalnum,notnull
    impl_id:naturalnum,notnull
}


db_exec_plsql binding_install "select acs_sc_binding__new($contract_id,$impl_id)"

ad_returnredirect ""
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
