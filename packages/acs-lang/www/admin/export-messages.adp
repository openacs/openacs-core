<master>
  <property name="title">@page_title;noquote@</property>

Export results for
<if @package_key@ nil>
  <b>all packages</b>
</if>
<else>
package <b>@package_key@</b>
</else>
and
<if @locale@ nil>
  <b>all locales</b>
</if>
<else>
locale <b>@locale@</b>
</else>.

<p>
  Export complete.
</p>

<if @package_key@ not nil>
  <p>
    Catalog files are stored in the directory <b>@catalog_dir@</b>.
  </p>
</if>

<ul class="action-links">
  <li><a href="@return_url@">Return</a></li>
</ul>

