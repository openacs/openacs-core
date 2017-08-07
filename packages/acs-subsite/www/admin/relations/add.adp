<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Add @role_pretty_name;noquote@ to @group_info.group_name;noquote@</property>

<blockquote>

<if @party_id@ nil>
  <if @allow_out_of_scope_p;literal@ false>
    You can select an existing @object_type_two_name@ from this subsite below.
    <br>
    If the @object_type_two_name@ that you want to add as @role_pretty_name@
    to @group_info.group_name@ is not listed below, then you can either
    <ul>
    <li><a href="@add_out_of_scope_url@">select an existing @object_type_two_name@ from the system</a>, or
    <li><a href="@add_party_url@">add a new @object_type_two_name@ to the system</a>.
    </ul>
  </if><else>
    You can select an existing @object_type_two_name@ from the system below.
    <br>
    If there are too many options, then you can
    <a href="@add_in_scope_url@">select an existing @object_type_two_name@ from this subsite</a>. 
    <br>
    You can also 
    <a href="@add_party_url@">add a new @object_type_two_name@ to the system</a>.
  </else>
</if>
<else>
Add @party_name@ as @role_pretty_name@ of @group_info.group_name@ . . .
</else>
<p>

<formtemplate id="add_relation"></formtemplate>

</blockquote>