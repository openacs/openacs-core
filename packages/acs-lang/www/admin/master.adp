<master>
  <if @title@ not nil><property name="title">@title;noquote@</property></if>
  <if @focus@ not nil><property name="focus">@focus;noquote@</property></if>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>

  <if @context_bar@ not nil><p>@context_bar;noquote@<p></if>

<slave>
