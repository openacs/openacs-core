<!-- Dark blue frame -->
<table bgcolor="#6699CC" cellspacing="0" cellpadding="4" border="0">
<tr><td>

<!-- Light blue pad -->
<table border="0" cellspacing="0" cellpadding="3" bgcolor="#99CCFF">
<tr><td>

    <h2>@info.type@ @info.name@</h2>

    <p>@info.header@</p>

    <table cellpadding="3" cellspacing="0" border="0">
      <if @info.author@ not nil>
        <tr><th align="left">Author:</th><td align="left">@info.author@</td></tr> 
      </if>
      <if @info.return@ not nil>
        <tr><th align="left">Returns:</th><td align="left">@info.return@</td></tr>
      </if>
      <tr><th align="left" colspan="2">Parameters:</th><tr>
      <tr><td align="left" colspan="2">
        <if @params:rowcount;literal@ gt 0>
          <blockquote><table border="0" cellpadding="0" cellspacing="1">
            <multiple name=params>
              <tr><th align="right" valign="top">@params.name@:</th>
                  <td>&nbsp;&nbsp;</td><td>@params.value@</td></tr>
            </multiple>
          </table></blockquote>
        </if>
        <else>
          <em>Not yet documented</em>
        </else></td>
      </tr>
      <tr><th align="left" colspan="2">Declaration:</th></tr>
      <tr align="left"><td colspan="2" align="left">
<pre><kbd>
@code@
</kbd></pre>
      </td></tr>
      <if @info.see@ not nil>
        <tr><th align="left" valign="top">See Also:</th><td>@info.see@</td></tr>
      </if>
    </table>
<!-- Light blue pad -->
</td></tr>
</table>

<!-- Dark blue frame -->
</td></tr>
</table>

<p>&nbsp;</p>
