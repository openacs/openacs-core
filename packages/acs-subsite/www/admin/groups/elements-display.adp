<master>
<property name="context">@context;noquote@</property>
<property name="title">@role_pretty_plural;noquote@ of @group_name;noquote@</property>

<include src="elements-display-list" group_id="@group_id;noquote@" rel_type="@rel_type;noquote@" member_state="@member_state;noquote@">

<if @member_state@ eq approved or @member_state@ eq "">
    <if @create_p@ eq 1>
      <ul>
        <li> <a href=../relations/add?group_id=@group_id@&rel_type=@rel_type_enc@&return_url=@return_url_enc@>
        Add a @role_pretty_name@</a>
        </li>
      </ul>
    </if>
</if>
