  <master>
    <property name="title">@page_title;noquote@</property>
    <property name="context">@context;noquote@</property>
    <h4>util_memoize caches</h4>

    <blockquote>
      <table cellpadding=3>
	  <tr bgcolor="#eeeeee">
	    <th>Name</th>
	    <th>Entries</th>
	    <th>Flushed</th>
	    <th>Hit Rate</th>
	    <th>Size</th>
	    <th>Max Size</th>
	    <th>&nbsp;</th>
	  </tr>
	  <multiple name="caches">
	    <if @caches.rownum@ odd>
	      <tr bgcolor="#eef8f8">
	    </if>
	    <else>
	      <tr bgcolor="#f8f8ee">
	    </else>
	      <td><b>@caches.name@</b></td>
	      <td align=right>@caches.entries@</td>
	      <td align=right>@caches.flushed@</td>
	      <td align=right>@caches.hit_rate@%</td>
	      <td align=right>@caches.size@</td>
	      <td align=right>@caches.max@</td>
	      <td align=center>&nbsp;
	      <a href="flush-cache?suffix=@caches.name@">flush</a>&nbsp;
	      </td>
	    </tr>
	  </multiple>

      </table>

      <form action="show-util-memoize" method=get>
	Show names that contain
	<%
	#<input name="pattern_type" type="radio" value="start">start with
	#<input name="pattern_type" type="radio" value="contain">contain
	%>
	<input name="pattern" type="text" value="">
	<input type="submit" value="Search">
      </form>

      <blockquote>
	<font color="#994444">Notes:
	<ul>
	  <li>This currently only searches the primary "util_memoize" cache
	</ul>
	</font> 
      </blockquote>

    </blockquote>
