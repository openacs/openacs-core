<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

<h1>@page_title@</h1>

<if @too_many_subsites_p@ gt 0>
  <p>Too many subsites to display: @subsite_number@</p>
</if>
<else>
<if @subsites:rowcount@ gt 0>
    <listtemplate name="subsites" style="table-2third"></listtemplate>
</if>
</else>

<p>
<a class="button" href="/admin/subsite-add">#acs-subsite.Create_new_subsite#</a>
</p>


