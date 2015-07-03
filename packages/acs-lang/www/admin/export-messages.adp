<master>
  <property name="doc(title)">@page_title;literal@</property>

<p>#acs-lang.Export_results_for#</p>

<ul>
  <li>#acs-lang.Package_# 
    <strong>
      <if @package_key@ nil>#acs-lang.all_packages#</if>
      <else>@package_key@</else>
    </strong>
  </li>
  <li>#acs-lang.Locale_#
    <strong>
      <if @locale@ nil>#acs-lang.all_locales#</if>
      <else>@locale@</else>
    </strong>
  </li>
</ul>

<p>
  #acs-lang.Export_complete#
</p>

<if @package_key@ not nil>
  <p>
    #acs-lang.Catalog_files_are_stored_in_the_directory# <strong>@catalog_dir@</strong>
  </p>
</if>

<ul class="action-links">
  <li><a href="@return_url@">#acs-lang.Return#</a></li>
</ul>

