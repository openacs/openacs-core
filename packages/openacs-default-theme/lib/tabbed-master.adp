<master src="/packages/openacs-default-theme/lib/plain-master">
<if @doc@ defined><property name="&doc">doc</property></if>
<if @body@ defined><property name="&body">body</property></if>
<if @head@ not nil><property name="head">@head;literal@</property></if>
<if @focus@ not nil><property name="focus">@focus;literal@</property></if>
<if @context@ not nil><property name="context">@context;literal@</property></if>
<property name="&navigation">navigation</property>

<slave>
