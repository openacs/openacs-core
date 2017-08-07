<html><head><title>Datasource for @code_stub@</title></head>

<body bgcolor="white">
<h3>Data sources for @code_stub@.acs</h3>

<multiple name="datasources">
<strong>@datasources.name@</strong>
<table>
<tr><td align="left">Type:</td><td>@datasources.structure@</td></tr>
<tr><td>Comments:</td><td>@datasources.comment@</td></tr>
   <if @datasources.structure@ in multirow multilist>
     <tr><th align="left">Columns:</th><tr>
     <tr><td align="left" colspan="2">
     <blockquote>
     <table border="0" cellpadding="0" cellspacing="1">
     <group column="name">
       <tr><th align="right" valign="top">@datasources.column_name@</th><td>&nbsp;&nbsp;</td><td>@datasources.column_comment@</td><tr>
     </group>
     </table>
     </blockquote>	 
   </if>
   <if @datasources.structure@ in form>
     <tr><th align="left">Input options:</th><tr>
     <tr><td align="left" colspan="2">
     <blockquote>
     <table border="0" cellpadding="0" cellspacing="1">
     <group column="name">
     <tr><th align="right" valign="top">@datasources.input_name@</th><td>&nbsp;&nbsp;</td><td><em>@datasources.input_type@</em>; @datasources.input_comment@</td><tr>
     </group>
     </table>
     </blockquote>
   </if>
	   
</table>
<p>
</multiple>

</body>
</html>
