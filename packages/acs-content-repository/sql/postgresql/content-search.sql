------------------------------------------------------------
-- declare CR as a content provider for search/indexing interface
------------------------------------------------------------


select acs_sc_impl__new(
	   'FtsContentProvider',		-- impl_contract_name
           'acs-content-repository',            -- impl_name
	   'acs-content-repositorys'            -- impl_owner_name
);

select acs_sc_impl_alias__new(
           'FtsContentProvider',		-- impl_contract_name
           'acs-content-repository',            -- impl_name
	   'datasource',			-- impl_operation_name
	   'content_search__datasource',        -- impl_alias
	   'TCL'				-- impl_pl
);

select acs_sc_impl_alias__new(
           'FtsContentProvider',		-- impl_contract_name
           'acs-content-repository',            -- impl_name
	   'url',				-- impl_operation_name
	   'content_search__url',               -- impl_alias
	   'TCL'				-- impl_pl
);

-- triggers queue search interface to modify search index after content
-- changes.

create function content_search__itrg ()
returns opaque as '
begin
    perform search_observer__enqueue(new.revision_id,''INSERT'');
    return new;
end;' language 'plpgsql';

create function content_search__dtrg ()
returns opaque as '
begin
    perform search_observer__enqueue(old.revision_id,''DELETE'');
    return old;
end;' language 'plpgsql';

create function content_search__utrg ()
returns opaque as '
begin
    insert into search_observer_queue (
        object_id,
	event
    ) values (
        old.revision_id,
        ''UPDATE''
    );
    return new;
end;' language 'plpgsql';


create trigger content_search__itrg after insert on cr_revisions
for each row execute procedure content_search__itrg (); 

create trigger content_search__dtrg after delete on cr_revisions
for each row execute procedure content_search__dtrg (); 

create trigger content_search__utrg after update on cr_revisions
for each row execute procedure content_search__utrg (); 




