<p>
The configured version of @resource_name@ is
<i>@version@</i><small> <adp:icon title="Configured via @configured_via@" name="form-info-sign"></small>
(newest version on cdnjs: <i>@newest_version@</i>).
<ul class="action-links ms-3">
<if @modifyPackageParameterURL@ not nil>
<li>You might <a title="Change the value of the package parameter @parameter_name@" href="@modifyPackageParameterURL@">modify the parameter value</a> or
   <a title="Delete the package parameter @parameter_name@ and its value. The version number might be provided via NaviServer configuration value or from the default settings." href="@deletePackageParameterURL@">delete the package parameter</a> "<i>@parameter_name@</i>".</li>
</if>
<if @addPackageParameterURL@ not nil>
<li>You might pin the version number by
   <ul><li>
   <a title="Add the global package parameter @parameter_name@ for the package @package_key@ with the default @version@"
      href="@addPackageParameterURL@">adding the global package parameter</a>
     <i>@parameter_name@</i> for this instance, or</li>
    <li>by configuring the version number by adding a section of the following
    form to your NaviServer configuration file:<p>

<pre class="bg-light ms-3 px-3 py-1 border w-75">
ns_section ns/server/${server}/acs/@package_key@ {
    ns_param @parameter_name@ @version@
}</pre></li>
    </ul>
    </li>
</if>
<if @versionCheckURL@ not nil><li>You might check available versions
  <a href="@versionCheckURL@" title="Check is performed at @versionCheckURL@">available upstream</a>.</li>
</if>
<if @vulnerabilityCheckURL@ not nil>
  <li>You might check on Synk the
    <if @vulnerabilityCheckVersionURL@ not nil>a vulnerability status for version
    <a href="@vulnerabilityCheckVersionURL@" title="Check includes only direct vulnerabilities">@version@<sup>
    <if @vulnerabilityCheckResult@ true><span class="text-danger"><adp:icon name="warn"></span></if>
    <else><span class="text-success"><adp:icon name="radio-checked"></span></else>
    </sup>
    </a> and
    </if>
    for <a href="@vulnerabilityCheckURL@">all released versions</a> of @resource_name@
    (See also: <a href="@vulnerabilityAdvisorURL@">Snyk Advisor</a>). 
  </li>
</if>
</ul>
<if @resources@ not nil><p>The configured version of @resource_name@ is installed locally
under <i>@resources@</i>.</if>
<else><p>In the current installation the @resource_name@ is used via CDN <i>@cdn@</i>.
  <if @writable@ true>
  <p>Do you want to <a href="@download_url@" class="button">download</a>
  version @version@ of @resource_name@ to your filesystem?</p>
  </if>
  <else>
  <p>The directory <i>@path@</i> is NOT writable for the server. In
  order to be able to download the @resource_name@ via this web interface,
  please change the permissions so that OpenACS can write to it.</p>
  </else>
</else>

<p>For <a href="https://openacs.org/xowiki/external-javascript-packages">background
and OpenACS policies</a> concerning the management of external
packages on OpenACS.org.</p>
