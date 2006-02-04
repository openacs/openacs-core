select acs_sc_impl__delete(
	   'FtsContentProvider',		-- impl_contract_name
           'template_demo_note'				-- impl_name
);




drop trigger template_demo_notes__utrg on notes;
drop trigger template_demo_notes__dtrg on notes;
drop trigger template_demo_notes__itrg on notes;



drop function template_demo_notes__utrg ();
drop function template_demo_notes__dtrg ();
drop function template_demo_notes__itrg ();

