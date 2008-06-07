create table notification_email_hold (
    reply_id			integer
				constraint notification_email_hold_pk primary key
				constraint notif_email_hold_reply_id_fk
				references notification_replies(reply_id),
    to_addr			text,
    headers 			text,
    body			text
);
