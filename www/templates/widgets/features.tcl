ad_page_contract {
    @author Ola Hansson ola@polyxena.net
    @creation-date 2002-08-06
} {
} -properties {
    title:onevalue
    n_feature_items:onevalue
    feature_limit:onevalue
    feature_items:multirow
}

set n_feature_items 3
set feature_limit [expr $n_feature_items + 1]


etp::get_content_items -package_id 4053 -limit $feature_limit \
                       -result_name feature_items
#etp::get_content_items -package_id 3138 -limit $feature_limit \
                       -result_name feature_items