ad_page_contract {

    @author Neophytos Demetriou

} {
    contract_id:integer
    impl_id:integer
}


db_exec_plsql binding_uninstall "select acs_sc_binding__delete($contract_id,$impl_id)"

ad_returnredirect ""
