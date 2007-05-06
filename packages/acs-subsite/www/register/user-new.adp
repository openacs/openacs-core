<master>
  <property name="title">#acs-subsite.Register#</property>
  <property name="context">{#acs-subsite.Register#}</property>
  <property name="focus">register.email</property>

<include src="@user_new_template@" email="@email@" return_url="@return_url;noquote@" />
