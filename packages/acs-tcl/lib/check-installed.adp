<p>
The configured version of @resource_name@ is @version@ (newest on cdnjs: @newest_version@).<br>
<if @versionCheckURL@ not nil>You might check for various versions <a href="@versionCheckURL@">available upstream</a>. </if>
<if @vulnerabilityCheckURL@ not nil><br>Snyk provides
  <if @vulnerabilityCheckVersionURL@ not nil>a
  vulnerability check for version <a href="@vulnerabilityCheckVersionURL@">@version@</a> and
</if>
  checks for <a href="@vulnerabilityCheckURL@">all released versions</a> of @resource_name@. 
</if>

<if @resources@ not nil><p>The configured version of @resource_name@ is installed locally
under <strong>@resources@</strong>.</if>
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
