<master>
<property name=title>@title;noquote@</property>
<property name="context">@context;noquote@</property>

<div style="float: right;">
  <include src="/packages/acs-api-browser/lib/search">
</div>

<h3>Installed Enabled Packages</h3>
<ul>
  
<multiple name="installed_packages">
  <li><a
   href="package-view?version_id=@installed_packages.version_id@">@installed_packages.pretty_name@
   @installed_packages.version_name@</a></li>
</multiple>

</ul>

<h3>Disabled Packages</h3>


<if @disabled_packages:rowcount@ eq 0>
 <b>NONE</b>  
</if>
<else>
 <multiple name="disabled_packages">
  <ul>
   <li>@disabled_packages.pretty_name@ @disabled_packages.version_name@</a>
  </ul>
 </multiple>
</else>


<h3>Uninstalled Packages</h3>

<if @uninstalled_packages:rowcount@ eq 0>
<b>NONE</b>
</if>
<else>
 <multiple name="uninstalled_packages">
  <ul>
   <li>@uninstalled_packages.pretty_name@ @uninstalled_packages.version_name@</a>
  </ul>
 </multiple>
</else>

<br clear="both">
