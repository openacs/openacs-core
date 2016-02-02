CREATE OR REPLACE FUNCTION content_item_search__utrg () RETURNS trigger AS $$
BEGIN
    if new.live_revision is not null and coalesce(old.live_revision,0) <> new.live_revision
    and (select publish_date from cr_revisions where revision_id=new.live_revision) <= current_timestamp then
        perform search_observer__enqueue(new.live_revision,'INSERT');        
    end if;

    if old.live_revision is not null and old.live_revision <> coalesce(new.live_revision,0)
    and (select publish_date from cr_revisions where revision_id=old.live_revision) <= current_timestamp then
        perform search_observer__enqueue(old.live_revision,'DELETE');
    end if;
    if old.live_revision is not null and new.publish_status = 'expired' then
        perform search_observer__enqueue(old.live_revision,'DELETE');
    end if;

    return new;
END;
$$ LANGUAGE plpgsql;

