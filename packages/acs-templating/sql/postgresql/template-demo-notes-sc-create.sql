--
-- packages/template-demo-notes/sql/notes-sc-create.sql
--
--
-- This sets up the service contracts that make the text in notes
-- available for indexing by the search package. See documentation 
-- on the packages 'search' and 'acs-service-contract'.
--
-- This notes package has been altered by prepending "template-demo-"
-- to all identifiers, for use by the template demos page.
--


select acs_sc_impl__new(
	   'FtsContentProvider',		-- impl_contract_name
           'template_demo_note',				-- impl_name
	   'template_demo_notes'				-- impl_owner_name
);

select acs_sc_impl_alias__new(
           'FtsContentProvider',		-- impl_contract_name
           'template_demo_note',           			-- impl_name
	   'datasource',			-- impl_operation_name
	   'template_demo_notes__datasource',     		-- impl_alias
	   'TCL'				-- impl_pl
);

select acs_sc_impl_alias__new(
           'FtsContentProvider',		-- impl_contract_name
           'template_demo_note',           			-- impl_name
	   'url',				-- impl_operation_name
	   'template_demo_notes__url',			-- impl_alias
	   'TCL'				-- impl_pl
);


create function template_demo_notes__itrg ()
returns trigger as '
begin
    perform search_observer__enqueue(new.template_demo_note_id,''INSERT'');
    return new;
end;' language 'plpgsql';

create function template_demo_notes__dtrg ()
returns trigger as '
begin
    perform search_observer__enqueue(old.template_demo_note_id,''DELETE'');
    return old;
end;' language 'plpgsql';

create function template_demo_notes__utrg ()
returns trigger as '
begin
    perform search_observer__enqueue(old.template_demo_note_id,''UPDATE'');
    return old;
end;' language 'plpgsql';


create trigger template_demo_notes__itrg after insert on template_demo_notes
for each row execute procedure template_demo_notes__itrg (); 

create trigger template_demo_notes__dtrg after delete on template_demo_notes
for each row execute procedure template_demo_notes__dtrg (); 

create trigger template_demo_notes__utrg after update on template_demo_notes
for each row execute procedure template_demo_notes__utrg (); 
