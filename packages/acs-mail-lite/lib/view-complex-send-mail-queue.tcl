# 2006/11/17 created (nfl)

template::list::create \
    -name get_all_complex_queued_messages \
    -selected_format normal \
    -multirow messages \
    -elements {
	creation_date { label "[_ acs-mail-lite.Queueing_time]" }
	from_addr { label "[_ acs-mail-lite.Sender]" }
	to_addr { label "[_ acs-mail-lite.Recipients]" }
	subject { label "[_ acs-mail-lite.Subject]" }
        locking_server { label "[_ acs-mail-lite.Queue_server]" }
    }
	
db_multirow messages get_all_complex_queued_messages {}
