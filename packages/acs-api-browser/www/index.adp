<master>
<property name=title>@title;noquote@</property>
<property name="context">@context;noquote@</property>

<div style="float: right;">
  <include src="/packages/acs-api-browser/lib/search">
</div>

<div style="float: left; width: 60%;">
<h3>Installed Enabled Packages</h3>
<ul>
  
<multiple name="installed_packages">
  <li><a
   href="package-view?version_id=@installed_packages.version_id@">@installed_packages.pretty_name@
   @installed_packages.version_name@</a></li>
</multiple>

</ul>

<if @disabled_packages:rowcount@ gt 0>
  <h3>Disabled Packages</h3>
 <multiple name="disabled_packages">
  <ul>
   <li>@disabled_packages.pretty_name@ @disabled_packages.version_name@</a>
  </ul>
 </multiple>
</if>


<if @uninstalled_packages:rowcount@ gt 0>
  <h3>Uninstalled Packages</h3>
 <multiple name="uninstalled_packages">
  <ul>
   <li>@uninstalled_packages.pretty_name@ @uninstalled_packages.version_name@</a>
  </ul>
 </multiple>
</if>

<br clear="both">
</div>
