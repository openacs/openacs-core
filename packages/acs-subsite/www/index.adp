<master>
<property name="title">@subsite_name;noquote@</property>
<property name="context">@context;noquote@</property>

<if @user_id@ ne 0>
  <if @group_member_p@ true>
    <span class="button"><a href="group-leave" class="button" title="Leave this group">Leave group</a></span>
  </if>
  <else>
    <if @can_join_p@ true>
      <if @group_join_policy@ eq "open">
        <span class="button"><a href="group-join" class="button" title="Join this group">Join group</a></span>
      </if>
      <else>
        <span class="button"><a href="group-join" class="button" title="Request membership of this group">Request membership</a></span>
      </else>
    </if>
  </else>
</if>

<ul>
 <if @nodes:rowcount@ eq 0> 
  <li>(no packages)</li>
 </if>
 <else>
  <multiple name="nodes">
    <li><a href="@nodes.url@">@nodes.name@</a></li>
  </multiple>
 </else>

 <if @admin_p@ eq 1> 
  <p>
   <li> <a href="admin/">@subsite_name@ Administration</a></li>
  </p>
 </if>
</ul>

