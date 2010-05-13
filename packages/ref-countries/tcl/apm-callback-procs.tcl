ad_library {

    Installation procs for ref-countries

    @author Emmanuelle Raffenne (eraffenne@gmail.com)

}

namespace eval ref_countries {}
namespace eval ref_countries::apm {}

ad_proc -private ref_countries::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {  
            5.6.0d1 5.6.0d2 {

                set new_countries {"ÅLAND ISLANDS" AX
                    "BOLIVIA, PLURINATIONAL STATE OF" BO
                    "CÔTE D'IVOIRE" CI
                    "GUERNSEY" GG
                    "ISLE OF MAN" IM
                    "JERSEY" JE
                    "KAZAKHSTAN" KZ
                    "MACAO" MO
                    "MONTENEGRO" ME
                    "RÉUNION" RE
                    "SAINT BARTHÉLEMY" BL
                    "SAINT MARTIN" MF
                    "SERBIA" RS
                    "TIMOR-LESTE" TL
                    "VENEZUELA, BOLIVARIAN REPUBLIC OF" VE}

                foreach {name code} $new_countries {
                    set exists_p [db_string get_country {select count(*) from countries where iso = :code} -default 0]

                    if { $exists_p } {
                        db_dml update_country {
                            update countries set default_name = :name
                            where iso = :code
                        }
                    } else {
                        db_dml insert_country {
                            insert into countries (iso, default_name)
                            values (:code, :name)
                        }
                    }
                }
            }
        }
}
