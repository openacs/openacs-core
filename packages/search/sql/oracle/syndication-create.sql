create table syndication (
        object_id       integer
                        constraint syndication_object_id_fk
                        references acs_objects (object_id) on delete cascade
                        constraint syndication_pk
                        primary key,
        last_updated    date default sysdate 
			constraint syndication_last_updated_nn not null,
        rss_xml_frag    blob,
        body            blob,
        url             blob
);


comment on table syndication is 'stores xml fragments for consolidating into rss feeds. Also stores an html version of the content item
         and it''s url from the link field of the rss';
