<master>
<property name="head">
   <style>
   dl {background-color: #e4e4e4;}
   dl dd {margin: 0px 0px 10px 40px;}
   </style>
</property>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<h2> @title@ </h2>
  <dl>
    <dt><b>Description:</b></dt><dd>@component_desc;noquote@</dd>
    <dt><b>Defined in file:</b></dt><dd>@component_file@</dd>
    <dt><b> Component body </b> </dt>
    <dd><pre>
      @component_body@
    </pre></dd>
  </td>
</dl>
