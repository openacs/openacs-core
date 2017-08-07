<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="focus">lookup.key</property>

<h1>#acs-lang.Look_up_message#</h1>

<formtemplate id="lookup"></formtemplate>

<if @message_p;literal@ true>
  <h2>#acs-lang.Translated_Message#</h2>
  <p>@message@</p>
</if>

<if @edit_url@ not nil>
  <ul class="action-links">
    <li><a href="@edit_url@">#acs-lang.Edit_this_message#</a></li>
  </ul>
</if>

