<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>

<h1>Delete @locale_label@</h1>

<p>Are you sure you want to delete @locale_label@ which locale is @locale@?</p>

<form action="locale-delete">
@form_export_vars;noquote@
<input type="submit" value="Confirm delete">
</form>
