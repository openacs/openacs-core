<master>
  <property name="doc(title)">@page_title;literal@</property>

<h1>Site-Wide Administration</h1>

<include src="/packages/acs-admin/lib/site-wide-services"
    nr_subsites="@subsite_number;literal@" >

<if @packages:rowcount@ gt 0>
  <h3>Site-Wide Package Administration</h3>

  <p>Manage application packages with site-wide administration facilities.
  These packages have either site-wide parameters (package
  parameters valid for every instance of the package) or they have an
  own web interface for site-wide administration (www/sitewide-admin).
  
  <listtemplate name="packages" style="table-2third"></listtemplate>
  <p>
</if>


<h3>Site-Wide Service Administration</h3>
<p>Manage service packages having either parameters or pages (for admins or users):
</p>
<include src="/packages/acs-admin/lib/service-parameters">
