<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<html>
  <body>
  <table width="100%"><tr><td bgcolor=#e4e4e4>
    <h2> @title@ </h2>
    <blockquote>
    <dt><b>Description:</b></dt><dd>@component_desc@</dd>
    <dt><b>Defined in file:</b></dt><dd>@component_file@</dd>
    <dt><b> Component body </b> </dt>
    <dd><pre>
      @component_body@
    </pre></dd>
    </blockquote>
  </td></tr></table>
  </body>
</html>
