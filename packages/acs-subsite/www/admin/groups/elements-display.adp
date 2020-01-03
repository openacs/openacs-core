<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">@role_pretty_plural;noquote@ of @group_name;noquote@</property>

<include src="elements-display-list" group_id="@group_id;literal@" rel_type="@rel_type;literal@" member_state="@member_state;literal@">

<if @member_state@ eq approved or @member_state@ eq "">
    <if @create_p;literal@ true>
      <ul>
        <li> <a href="@add_url@">
        Add a @role_pretty_name@</a>
        </li>
      </ul>
    </if>
</if>
