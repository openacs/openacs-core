

<table border="1" cellpadding="4" cellspacing="0">
  <tr>
    <th>Package</th>
    <th>Description</th>
  </tr>
  <multiple name="pkgs">
    <tr>
      <td style="text-align:center;" valign="center" width="120">
        <a href="/xowiki/@pkgs.package_key@">@pkgs.package_key@</a>
      </td>
      <td style="border-color:gray;">
        <strong>@pkgs.pretty_name@:</strong><br><em>@pkgs.summary@</em>
        <p>@pkgs.description;noquote@
        <p><small>@pkgs.package_key@ @pkgs.version@ released @pkgs.release_date@ 
        <if @pkgs.license@ not nil>
	   on
	   <if @pkgs.license_url@ not nil><a href="@pkgs.license_url@">@pkgs.license@</a></if>
           <else>@pkgs.license@</else>
           license
        </if>
	<if @pkgs.vendor@ not nil> by @pkgs.vendor@</if>
	<if @pkgs.maturity@ not nil><br>@pkgs.maturity@: @pkgs.maturity_text@</if>
	</small>
      </td>
   </tr>
  </multiple>
</table>
