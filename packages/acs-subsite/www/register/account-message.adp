<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<p> @message;noquote@ </p>

<if @return_url@ not nil>
  <b>&raquo;</b> <a href="@return_url@">Continue working with @system_name@</a>
</if>

