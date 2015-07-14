<master>
  <property name="context">@context;literal@</property>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="focus">register.first_names</property>

<include src="@user_new_template;literal@"
    self_register_p="0" 
    email="@email;literal@" 
    return_url="." 
    rel_group_id="@rel_group_id;literal@" />
