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
    <dt><strong>Description:</strong></dt><dd>@component_desc;noquote@</dd>
    <dt><strong>Defined in file:</strong></dt><dd>@component_file@</dd>
    <dt><strong> Component body </strong> </dt>
    <dd><pre>
      @component_body@
    </pre></dd>
</dl>
