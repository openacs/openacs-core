
set user_id [ad_conn user_id]
set return_url [ad_return_url]
set register_url "/register/?[export_vars return_url]"
if !$user_id {
    set login_p 0
} else {
    set login_p 1
    set name [db_string get_user_name "select first_names || ' ' || last_name from persons where person_id = $user_id" -default "unknown user"]
}