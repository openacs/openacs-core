<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">lookup.key</property>

<formtemplate id="lookup"></formtemplate>

<if @message_p@ true>
  <h2>Translated Message</h2>
  <if @message@ nil><p><i>blank</i></if>
  <else><p>@message@</p></else>
</if>

<if @edit_url@ not nil>
  <ul class="action-links">
    <li><a href="@edit_url@">Edit this message</a></li>
  </ul>
</if>

