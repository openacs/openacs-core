<table width="100%"><tr><td width="100%" bgcolor="#CCCCFF">
  <a name="@info.proc_name@"><font size="+1" weight=bold>@info.proc_name@</font></a>
  <if @info.author@ not nil><br><small><em>&nbsp;&nbsp;by @info.author@</em></small></if>
</td>
</tr>
<tr><td>
<blockquote>
@info.description@
</blockquote>
<dl>
<if @params:rowcount@ gt 0>
  <strong>Parameters:</strong>
  <table>
  <multiple name=params>
  <tr>
  <td align="right"><code>@params.name@</code>
  <if @params.default@ not nil>
    <if @params.default@ in required>@required_marker@</td>
       <td align="left">
    </if>
    <else>
     </td><td align="left"> <em>default</em> @params.default@; 
    </else>
  </if>
  @params.description@</td></tr>
  </multiple>
   </table>
</if>
<if @info.return@ not nil>
  <dt><strong>Returns:</strong>
  <dd>
  @info.return@
</if>
<if @options:rowcount@ gt 0>
  <dt><strong>Options:</strong>
  <table>
  <multiple name=options>
  <tr><td align="right"><code>@options.name@</code></td>
  <td align="left">
  <if @options.default@ not nil>
    <em>default</em> @options.default@;
  </if>
  @options.description@</td></tr>
  </multiple>
  </table>
</if>
<if @see:rowcount@ gt 0>
  <dt><strong>See Also:</strong>
  <multiple name=see>
    <dd>@see.type@ - <group column=type><a href="@see.url@">@see.name@</a></br></group>
  </multiple>
</if>
</dl>
</td>
</tr>
</table>
