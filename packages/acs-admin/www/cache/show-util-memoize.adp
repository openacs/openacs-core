  <master>
    <property name="doc(title)">@page_title;literal@</property>
    <property name="context">@context;literal@</property>

    Search for <strong><code>@pattern@</code></strong>:

    <if @matches:rowcount@ not nil and @matches:rowcount@ gt 0>
      @matches:rowcount@ matches found.<p></p>

      <if @full@ eq "f">
	Only the first 200 chars of key and value are shown.
	<a href="show-util-memoize?full=t&pattern=@pattern@">View
	  full results.</a>
      </if>
      <else>
	Full strings for key and value shown.
	<a href="show-util-memoize?full=f&pattern=@pattern@">View
	  short results.</a>
      </else>
      <table border="0" cellpadding="5" cellspacing="1">
	<tr bgcolor="#eeeeee">
	  <th>key</th>
	  <!--<th>time</th>
	  <th>value<br>size</th>-->
	  <th>value</th>
	  <th>&nbsp;</th>
	</tr>

	<multiple name="matches">
	    <if @matches.rownum@ odd>
	      <% set bg "#eef8f8" %>
	    </if>
	    <else>
	      <% set bg "#f8f8ee" %>
	    </else>
	    <tr bgcolor="@bg@">
	      <td valign="top">@matches.key@</td>
	      <td valign="top">@matches.value;noquote@</td>
	      <td valign="middle" rowspan="2">
		<form action=one method=post>
		  <input type="hidden" name="key" value="@matches.full_key@">
		  <input type="hidden" name="raw_date" value="@matches.raw_date@">
		  <input type="hidden" name="pattern" value="@pattern@">
		  <input type="submit" value="Show">
		</form>
	      </td>
	    </tr>
	    <tr bgcolor="@bg@">
	      <td align="right" colspan="2">
		<font color="#666666">
		  @matches.date@ - @matches.value_size@ bytes
		</font>
	      </td>
	    </tr>
	</multiple>

	</table>
	<p><!--
	<a href="flush?type=all&pattern=@pattern@">Flush all of these
	from the cache</a>-->
    </if>
    <else>
      <em>no matches found</em>
    </else>

