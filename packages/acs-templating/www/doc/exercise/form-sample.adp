<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html><head>
<title>My address book</title>
</head>

<body>
<strong>Add an entry to your address book
<formtemplate id="add_entry">


	<table>
  	<tr><td><strong><em>Name</em>:</strong></td>
  	<td><formwidget id="title"> <formwidget id="first_names"> <formwidget id="last_name">	 
	  </td></tr>
	  <tr><td><strong><em>Gender</em>:</strong></td><td>
	  <formgroup id="gender">@formgroup.label@ @formgroup.widget@
	  </formgroup>
	  <formerror id="gender"><br><font color=red><small>Please include gender information about your entry subject</small></font></formerror>
	  </td></tr>
	  <tr><td><strong><em>Birthday</em>:</strong></td><td><formwidget id="birthday"></td></tr>
	  <tr><td><strong><em>Address</em>:</strong></td><td><formwidget id="address"></td></tr>
	  <tr><td><strong><em>City</em>:</strong></td>
	      <td><formwidget id="city" size="29"> <strong> <em>State</em>:</strong><formwidget id="state"></td>
	  </tr>
	  <tr><td><strong><em>Zip</em>:</strong></td>
	      <td><formwidget id="zip"> <strong><em>Country</em>:</strong><formwidget id="country"></td>
	  </tr>
	  <tr><td><strong><em>Email</em>:</strong></td><td><formwidget id="email"></td></tr>
	  <tr><td><strong><em>Relation</em>:</strong></td>
	      <td><formgroup id="relationship"> @formgroup.widget@ @formgroup.label@ <br></formgroup></td>
	  </tr>
	  <tr><td><strong><em>Telephones<strong>:</em></td>
		<td><table><formgroup id="primary_phone">
		  <tr><td>@formgroup.widget@</td><td>@formgroup.label@</td>
	          <td><formwidget id="@formgroup.label@"></td></tr>
		</formgroup></table><small><em>please indicate your primary telephone</em></small>
	  </td></tr>
	  <tr><td colspan="2" align="center"><br><input type="submit" value="Enter"></td></tr>
	</table>
	</formtemplate>


<!-- NOTE: do not delete; all text between this line...
	
... and this line should not be deleted or altered while enslaving this page -->


<h3>Address Book:</h3>
<table>
<tr><th>Name</th><th>Address</th><th>Email</th><th>Telephone contact</th></tr>
<multiple name="address" maxrows="@num_rows@">
  <if @address.rownum@ odd>
    <tr bgcolor=white>
  </if>
  <else>
    <tr>
  </else>
    <td>@address.first_names@ @address.last_name@</td>
  <td>@address.address@<br>
      @address.city@, @address.state@ @address.zip@
  <if @address.country@ not nil and not in USA America>
    <br>@address.country@
  </if>
  </td>
  <td><a href="mailto:@address.email@">@address.email@</a></td>
  <td>phone stuff</td>
  </tr>

</multiple>
  <if @address:rowcount;literal@ eq 0>
    <tr><th align="center" colspan="4"><em>You currently have no entries in your addressbook</em></th></tr>
  </if>

</table>


<p>


<if Freddy in Fred Wilma Betty>
YES!
</if>
<else>
NO!
</else>



<hr>
<a href="mailto:templating@arsdigita.com">templating@arsdigita.com</a>
<!-- hhmts start -->
Last modified: Sun Oct  6 02:38:25 EDT 2002
<!-- hhmts end -->
</body> </html>








