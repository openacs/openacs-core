set context [list]

db_multirow defined_contracts defined_contracts {select contract_id,contract_name,contract_desc from acs_sc_contracts}

db_multirow valid_installed_binding valid_installed_binding ""

db_multirow valid_uninstalled_binding valid_uninstalled_binding ""

db_multirow invalid_uninstalled_binding invalid_uninstalled_binding ""

db_multirow orphan_implementation orphan_implementation ""

