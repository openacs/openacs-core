<h2>OpenACS @channel@ Core and compatibile packages</h2>
<p>Packages can be installed with the OpenACS Automated Installer on
your OpenACS site at <code>/acs-admin/install</code>.  Only packages
designated compatible with your OpenACS kernel will be shown.</p>
<table border="1" cellpadding="4" cellspacing="0">
  <tr>
    <th>Package</th>
    <th>Description</th>
    <th>Release</th>
  </tr>
  <multiple name="packages">
    <tr>
      <td style="border-color:gray; text-align:center" valign="center" ><b>@packages.pretty_name@</b></td>
      <td style="border-color:gray"><b>@packages.summary@</b><br>@packages.description;noquote@</td>
      <td style="border-color:gray">@packages.package_key@ @packages.version@
      <br> released @packages.release_date@ by @packages.vendor@</small></td>
   </tr>
  </multiple>
</table>
