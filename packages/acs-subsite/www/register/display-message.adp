<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>

<p> @message;noquote@ </p>

<if @continue_url@ not nil>
  <b>&raquo;</b> <a href="@continue_url@">@continue_label@</a>
</if>

