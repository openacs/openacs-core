<p>
The configured version of @resource_name@ is
<strong>@version@</strong><small> <adp:icon title="Configured via @configured_via@" name="form-info-sign"></small>
(newest version on cdnjs: @newest_version@).
<ul class="action-links ms-3">
<if @modifyPackageParameterURL@ not nil>
<li>You might <a href="@modifyPackageParameterURL@">modify the parameter value</a> or
   <a href="@deletePackageParameterURL@">delete the package parameter</a> "<i>@parameter_name@</i>".</li>
</if>
<if @addPackageParameterURL@ not nil>
<li>You might <a href="@addPackageParameterURL@">add the global package parameter</a> 
    "<i>@parameter_name@</i>" to pin the version number to the current value for this instance.</li>
</if>
<if @versionCheckURL@ not nil><li>You might check available versions <a href="@versionCheckURL@">available upstream</a>.</li> </if>
<if @vulnerabilityCheckURL@ not nil>
  <li>You might check on Synk the
    <if @vulnerabilityCheckVersionURL@ not nil>a
    vulnerability status for version <a href="@vulnerabilityCheckVersionURL@">@version@</a> and
    </if>
    for <a href="@vulnerabilityCheckURL@">all released versions</a> of @resource_name@. 
  </li>
</if>
</ul>
<if @resources@ not nil><p>The configured version of @resource_name@ is installed locally
under <i>@resources@</i>.</if>
<else><p>In the current installation the @resource_name@ is used via CDN <strong>@cdn@</strong>.
  <if @writable@ true>
  <p>Do you want to <a href="@download_url@" class="button">download</a>
  version @version@ of @resource_name@ to your filesystem?</p>
  </if>
  <else>
  <p>The directory <strong>@path@</strong> is NOT writable for the server. In
  order to be able to download the @resource_name@ via this web interface,
  please change the permissions so that OpenACS can write to it.</p>
  </else>
</else>
