# $Id$

set user_id [ad_get_user_id]



db_dml unused "update user_preferences set dont_spam_me_p = util.logical_negation(dont_spam_me_p) where user_id = :user_id"

ad_returnredirect "home"
