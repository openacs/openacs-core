<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<if @result@ not nil>
  <h2>Output</h2>
  <blockquote><pre>
  @result@
  </pre></blockquote>
</if>
<else>
  The callback has been invoked.
</else>

<p>
  <b>&raquo;</b> <a href="@return_url@">Go back</a>
</p>
