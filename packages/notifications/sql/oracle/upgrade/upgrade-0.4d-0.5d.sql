-- START Make oracle version cascade in all the places where the pg version does

-- Table notification_types_intervals
alter table notification_types_intervals drop constraint NOTIF_TYPE_INT_TYPE_ID_FK;
alter table notification_types_intervals 
        add constraint notif_type_int_type_id_fk 
        foreign key (type_id)
        references notification_types (type_id) 
        on delete cascade;

alter table notification_types_intervals drop constraint NOTIF_TYPE_INT_INT_ID_FK;
alter table notification_types_intervals 
        add constraint notif_type_int_int_id_fk 
        foreign key (interval_id)
        references notification_intervals (interval_id) 
        on delete cascade;

-- Table notification_types_del_methods
alter table notification_types_del_methods drop constraint NOTIF_TYPE_DEL_TYPE_ID_FK;
alter table notification_types_del_methods 
        add constraint notif_type_del_type_id_fk 
        foreign key (type_id)
        references notification_types (type_id) 
        on delete cascade;

alter table notification_types_del_methods drop constraint NOTIF_TYPE_DEL_METH_ID_FK;
alter table notification_types_del_methods 
        add constraint notif_type_del_meth_id_fk 
        foreign key (delivery_method_id)
        references notification_delivery_methods (delivery_method_id) 
        on delete cascade;

-- Table notification_requests
alter table notification_requests drop constraint NOTIF_REQUEST_TYPE_ID_FK;
alter table notification_requests
        add constraint notif_request_type_id_fk
        foreign key (type_id)
        references notification_types (type_id)
        on delete cascade;

-- END on delete cascade changes

-- TODO: other changes here
