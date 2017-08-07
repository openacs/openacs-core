<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<p> @message;noquote@ </p>

<if @continue_url@ not nil>
  <strong>&raquo;</strong> <a href="@continue_url@">@continue_label@</a>
</if>

