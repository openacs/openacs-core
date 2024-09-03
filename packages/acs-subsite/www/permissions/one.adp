  <master>
  <property name="doc(title)">#acs-subsite.Permissions_for_name#</property>
  <property name="context">@context;literal@</property>

  <p>[ <a href="@toggle_view_href@">@toggle_view_label@</a> ]</p>
  <h3>#acs-subsite.Direct_Permissions#</h3>

  <if @detail_p;literal@ true>
    <if @acl:rowcount;literal@ gt 0>
      <form method="get" action="revoke">
        @export_form_vars;noquote@
        <multiple name="acl">
          <if @mainsite_p@ true and @acl.grantee_id@ eq "-1">
            <div>@acl.grantee_name@, @acl.privilege@ <strong>#acs-subsite.perm_cannot_be_removed#</strong></div>
	  </if>
          <else>
            <input type="checkbox" name="revoke_list" value="@acl.grantee_id@ @acl.privilege@" 
              id="check_@acl.grantee_id@_@acl.privilege@">
            <label for="check_@acl.grantee_id@_@acl.privilege@">@acl.grantee_name@, @acl.privilege@</label><br>
          </else>
        </multiple>
    </if>
    <else>
      <p><em>#acs-subsite.none#</em></p>
    </else>
    <if @acl:rowcount;literal@ gt 0>
      <div><input type="submit" value="#acs-subsite.Revoke_Checked#"></div>
      </form>
    </if>
  @controls;noquote@
  </if><else>
    <include src="/packages/acs-subsite/www/permissions/perm-include" &="object_id" &="return_url" &="privs">
  </else>
    
  <h3>#acs-subsite.lt_Inherited_Permissions#</h3>

  <if @inherited_permissions_p;literal@ false>
    <p>@nr_inherited_permissions@ #acs-subsite.lt_Inherited_Permissions#
    [<a href="@show_inherited_permissions_href@">#acs-subsite.Show#</a>]
  </if>
  <else>
    <p>@nr_inherited_permissions@ #acs-subsite.lt_Inherited_Permissions#
    [<a href="@hide_inherited_permissions_href@">#acs-subsite.Hide#</a>]
    <if @inherited:rowcount;literal@ gt 0>
      <ul>
        <multiple name="inherited">
          <li>@inherited.grantee_name@, @inherited.privilege@</li>
        </multiple>
      </ul>
    </if>
    <else>
      <p><em>#acs-subsite.none#</em></p>
    </else>
  </else>
   

  <h3>#acs-subsite.Children#</h3>
  <if @children_p;literal@ true>
    <if @children:rowcount;literal@ gt 0>
      <ul>
        <multiple name="children">
          <li><a href="one?object_id=@children.c_object_id@">@children.c_name@</a> @children.c_type@</li>
        </multiple>
      </ul>

      [<a href="@hide_children_url@">#acs-subsite.Hide#</a>]
    </if>
    <else>
      <p><em>#acs-subsite.none#</em></p>
    </else>
  </if>

  <if @children_p;literal@ false>
    <if @num_children@ gt 0> #acs-subsite.lt_num_children_Children# [<a href="one?object_id=@object_id@&amp;children_p=t">#acs-subsite.Show#</a>]</if>
    <else>
      <em>#acs-subsite.none#</em>
    </else>
  </if>
  <if @application_url@ not nil>
    <p>
      [<a href="@application_url@">#acs-subsite.return_to_application#</a>]
    </p>
  </if>
  <else>
    <if @context_id@ not nil><p>[<a href="one?object_id=@context_id@">#acs-subsite.up_to_context_name#</a>]</p></if>
  </else>      

