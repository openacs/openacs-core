<master src="site-master">
  <property name="title">@title;noquote@</property>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>
  <if @context@ not nil><property name="context">@context;noquote@</property></if>
  <if @context_bar@ not nil><property name="context_bar">@context_bar;noquote@</property></if>
  <if @focus@ not nil><property name="focus">@focus;noquote@</property></if>
  <if @doc_type@ not nil><property name="doc_type">@doc_type;noquote@</property></if>
  <if @displayed_object_id@ not nil><property name="displayed_object_id">@displayed_object_id;noquote@</property></if>
<div id="page-body">
  <if @title@ not nil>
    <h1 class="page-title">@title;noquote@</h1>
  </if>
  <slave>
  <div style="clear: both;"></div>
</div>
