<p>
The current version of the @resource_name@ is @version@.
<if @resources@ not nil><p>This version of the @resource_name@ is installed locally
under <strong>@resources@</strong>.</if>
<else><p>In the current installation the @resource_name@ is used via CDN <strong>@cdn@</strong>.
  <if @writable@ true>
  <p>Do you want to <a href="@download_url@" class="button">download</a>
  version @version@ of @resource_name@ to your file system?</p>
  </if>
  <else>
  <p>The directory <strong>@path@</strong> is NOT writable for the server. In
  order to be able to download the @resource_name@ via this web interface,
  please change the permissions so that OpenACS can write to it.</p>
  </else>
</else>
