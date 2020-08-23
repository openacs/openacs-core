<?xml version="1.0"?>
<queryset>
 
<fullquery name="attribute::add.drop_attr_column">
  <querytext>
    alter table $table_name drop column $attribute_name
  </querytext>
</fullquery>


<fullquery name="attribute::add.add_column">
  <querytext>
    alter table $table_name add $attribute_name $sql_type
  </querytext>
</fullquery>


</queryset>
