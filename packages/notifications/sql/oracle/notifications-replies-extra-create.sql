create table notification_email_hold (
    reply_id			integer
    				references  notification_replies(reply_id)
				primary key,
    to_addr			text,
    body			text
);
