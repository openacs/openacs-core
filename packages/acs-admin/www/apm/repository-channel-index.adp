
<h2>OpenACS @channel@ Core and compatibile packages</h2>

<p>Packages can be installed with the OpenACS Automated Installer on
your OpenACS site at <code>/acs-admin/install</code>.  Only packages
designated compatible with your OpenACS kernel will be shown.</p>
<table border="1" cellpadding="4" cellspacing="0">
  <tr>
    <th>Package</th>
    <th>Status</th>
    <th>Description</th>
  </tr>
  <multiple name="packages">
    <tr>
      <td style="border-color:gray; text-align:center" valign="center" >
        <a href="/xowiki/@packages.package_key@"><b>@packages.pretty_name@</b></a>
      </td>
      <td>
        <if @packages.maturity@ not nil>@packages.maturity@: @packages.maturity_text@<br></if>
        <if @packages.license@ not nil>
           <small>
	   <if @packages.license_url@ not nil><a href="@packages.license_url@">@packages.license@</a></if>
           <else>@packages.license@</else>
           </small>
        </if>

      </td>
      <td style="border-color:gray">
        <b>@packages.summary@</b>
        <br>@packages.description;noquote@
        <p><small>@packages.package_key@ @packages.version@ released @packages.release_date@ 
	<if @packages.vendor@ not nil> by @packages.vendor@</if></small>

</td>
   </tr>
  </multiple>
</table>
