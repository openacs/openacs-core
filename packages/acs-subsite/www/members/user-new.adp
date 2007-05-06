<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@page_title;noquote@</property>
  <property name="focus">register.first_names</property>

<include src="@user_new_template@"
    self_register_p="0" 
    email="@email@" 
    return_url="." 
    rel_group_id="@group_id@" />
