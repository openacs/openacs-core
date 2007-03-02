<master src="/www/site-master">
<if @meta:rowcount@ not nil><property name="&meta">meta</property></if>
<if @link:rowcount@ not nil><property name="&link">link</property></if>
<if @script:rowcount@ not nil><property name="&script">script</property></if>
<if @doc@ defined><property name="&doc">doc</property></if>
<if @body@ defined><property name="&body">body</property></if>
<if @head@ not nil><property name="head">@head;noquote@</property></if>
<slave />
