<master>
  <property name="context">@context;literal@</property>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="focus">user_search.user_id</property>

<h1>#acs-subsite.Invite_a_user#</h1>

<if @subsite_p;literal@ true>

  <h2>#acs-subsite.Search_For_Exist_User#</h2>

  <p>
    #acs-subsite.lt_If_you_happen_to_know#
  </p>

  <formtemplate id="user_search"></formtemplate>

  <h2>#acs-subsite.Or_add_a_new_user#</h2>

  <p>
    #acs-subsite.lt_If_you_dont_think_the#
  </p>

</if>

<formtemplate id="user_create"></formtemplate>

<p>
You may use the <a href="user-batch-add">user bulk upload page</a> to add many users.
</p>
