
# Create a notification type
db_transaction {
    set interval_id [db_exec_plsql new_interval "declare begin
    :1 := notification_interval.new (name => 'hourly' , n_seconds => 3600, creation_user => NULL, creation_ip => NULL);
    end;
    "]
    
    set delivery_method_id [db_exec_plsql new_deliv_method "declare begin
    :1 := notification_delivery_method.new (short_name => 'email', pretty_name => 'Email', creation_user => NULL, creation_ip => NULL);
    end;
    "]
    
    set type_id [notification::type::new -short_name "test" -pretty_name "Test Notification" -description "foobar"]
    
    # enable both
    notification::type::interval_enable -type_id $type_id -interval_id $interval_id
    notification::type::delivery_method_enable -type_id $type_id -delivery_method_id $delivery_method_id
    
    set request_id [notification::request::new -type_id $type_id -user_id 2394 -interval_id $interval_id -delivery_method_id $delivery_method_id -object_id 2394]
}

doc_body_append $request_id

