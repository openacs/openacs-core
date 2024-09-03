<master>
<property name="doc(title)">@title;literal@</property>

<h1>@title;noquote@</h1>
<ul>
  <li><a href="applications/"><adp:icon name="boxes" title="Manage mounted packages"> #acs-subsite.Applications#</a></li>
  <li><a href="configure"><adp:icon name="admin" title="Modify subsite settings#"> #acs-subsite.Configure#</a></li>
  <li><a href="themes"><adp:icon name="palette"> #acs-subsite.Themes#</a></li>
  <li><a href="permissions"><adp:icon name="permissions" title="#acs-subsite.permissions#"> #acs-subsite.Permissions#</a></li>
  <li><a href="../members/"><adp:icon name="user" title="Manage subsite members#"> #acs-subsite.Members#</a></li>
  <li><a href="../shared/parameters?return_url=../admin"><adp:icon name="cog" title="#acs-admin.Parameters#"> #acs-subsite.Parameters#</a></li>
  <li><a href="subsite-add"><adp:icon name="add-new-item" title="Create a new subsite"> #acs-subsite.Create_new_subsite#</a></li>
  <if @convert_subsite_p;literal@ true>
    <li><a href="subsite-convert-type">#acs-subsite.Convert_to_descendent_subsite_type#</a></li>
  </if>
</ul>

<h3>#acs-subsite.Advanced_Features#</h3>

<ul>
  <li><a href="site-map/"><adp:icon name="sitemap" title="Manage sitemap"> #acs-subsite.Site_Map#</a></li>
  <li><a href="groups/">#acs-subsite.Groups#</a></li>
  <li><a href="group-types/">#acs-subsite.Group_Types#</a></li>
  <li><a href="rel-segments/">#acs-subsite.Relational_Segments#</a></li>
  <li><a href="rel-types/">#acs-subsite.Relationship_Types#</a></li>
  <li><a href="object-types/">#acs-subsite.Object_Types#</a></li>
  <!-- <li><a href="host-node-map/">#acs-subsite.Host_Node_Map#</a></li> -->
</ul>

<if @sw_admin_p;literal@ true>
  <h1>#acs-subsite.lt_For_Site-Wide_Adminis#</h1>
  <ul>
    <li>
    <a href="@full_acs_admin_url@">@acs_admin_name@</a> <span style="font-style:italic;color:#666;">(#acs-subsite.Site_wide_administration#)</span>
    </li>
  </ul>
</if>
