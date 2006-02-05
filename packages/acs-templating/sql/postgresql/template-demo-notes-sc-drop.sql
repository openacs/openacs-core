select acs_sc_impl__delete(
	   'FtsContentProvider',		-- impl_contract_name
           'template_demo_note'				-- impl_name
);




drop trigger template_demo_notes__utrg on template_demo_notes;
drop trigger template_demo_notes__dtrg on template_demo_notes;
drop trigger template_demo_notes__itrg on template_demo_notes;



drop function template_demo_notes__utrg ();
drop function template_demo_notes__dtrg ();
drop function template_demo_notes__itrg ();

