-- change triggers to index only live revisions --DaveB 2002-09-26
-- triggers queue search interface to modify search index after content
-- changes.
create or replace function content_search__itrg ()
returns opaque as '
begin
if (select live_revision from cr_items where item_id=new.item_id) = new.revision_id then	
	perform search_observer__enqueue(new.revision_id,''INSERT'');
    end if;
    return new;
end;' language 'plpgsql';

create or replace function content_search__dtrg ()
returns opaque as '
begin
    select into v_live_revision live_revision from
	cr_items where item_id=old.item_id;
    if old.revision_id=v_live_revision then
	perform search_observer__enqueue(old.revision_id,''DELETE'');
    end if;
    return old;
end;' language 'plpgsql';

create or replace function content_search__utrg ()
returns opaque as '
declare
    v_live_revision integer;
begin
    select into v_live_revision live_revision from
	cr_items where item_id=old.revision_id;
    if old.revision_id=v_live_revision then
	insert into search_observer_queue (
            object_id,
	    event
        ) values (
old.revision_id,
            ''UPDATE''
        );
    end if;
    return new;
end;' language 'plpgsql';

-- we need new triggers on cr_items to index when a live revision
-- changes

create function content_item_search__utrg ()
returns opaque as '
begin
    if new.live_revision is not null and coalesce(old.live_revision,0) <> new.live_revision then
	perform search_observer__enqueue(new.live_revision,''INSERT'');		
    end if;

    if old.live_revision is not null and old.live_revision <> coalesce(new.live_revision,0) then
	perform search_observer__enqueue(old.live_revision,''DELETE'');
    end if;

    return new;
end;' language 'plpgsql';

create trigger content_item_search__utrg before update on cr_items
for each row execute procedure content_item_search__utrg (); 
