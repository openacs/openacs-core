ad_page_contract {

    @author Neophytos Demetriou

} {
    contract_id:integer
    impl_id:integer
}


db_exec_plsql binding_install "select acs_sc_binding__new($contract_id,$impl_id)"

ad_returnredirect ""
