
set n_users [util_memoize {db_string select_n_users "select count(user_id) from users" -default "unknown"} 300]


# we seed with the no. of downloads on the old site.
# LARS 2003-08-18: I've taken this out because it makes us look stupid
# only 3088 downloads from 6774 users ... < .5 download per user
#
# set n_downloads [expr 2423 + [download_get_number [list 46390 47732 44010]]]

