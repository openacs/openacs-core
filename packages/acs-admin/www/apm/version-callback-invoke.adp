<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

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
  <strong>&raquo;</strong> <a href="@return_url@">Go back</a>
</p>
