<?xml version="1.0"?>

<queryset>

  <fullquery name="ref_language::set_data.get_lang">
    <querytext>

      select count(*) 
      from language_639_2_codes 
      where iso_639_2 = :iso2

    </querytext>
  </fullquery>

  <fullquery name="ref_language::set_data.update_lang">
    <querytext>

      update language_639_2_codes 
      set label = :label, iso_639_1 = :iso1
      where iso_639_2 = :iso2

    </querytext>
  </fullquery>

  <fullquery name="ref_language::set_data.insert_lang">
    <querytext>

      insert into language_639_2_codes 
      (iso_639_2, iso_639_1, label)
      values
      (:iso2, :iso1, :label)

    </querytext>
  </fullquery>

  <fullquery name="ref_language::set_iso1.get_lang">
    <querytext>

      select count(*) from language_codes
      where language_id = :code

    </querytext>
  </fullquery>

  <fullquery name="ref_language::set_iso1.update_lang">
    <querytext>

      update language_codes set name = :name
      where language_id = :code

    </querytext>
  </fullquery>

  <fullquery name="ref_language::set_iso1.insert_lang">
    <querytext>

      insert into language_codes (language_id, name)
      values (:code, :name)

    </querytext>
  </fullquery>

</queryset>
