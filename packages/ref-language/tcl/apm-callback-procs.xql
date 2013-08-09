<?xml version="1.0"?>

<queryset>

  <fullquery name="ref_language::apm::after_upgrade.drop_constraint">
    <querytext>
      alter table language_codes drop constraint language_codes_name_uq
    </querytext>
  </fullquery>

  <fullquery name="ref_language::apm::after_upgrade.drop_unique_index">
    <querytext>
      drop index language_codes_name_uq
    </querytext>
  </fullquery>

</queryset>
