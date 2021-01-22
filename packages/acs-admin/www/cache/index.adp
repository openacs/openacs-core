  <master>
    <property name="doc(title)">@page_title;literal@</property>
    <property name="context">@context;literal@</property>
    <h4>util_memoize caches</h4>

    <blockquote>
      <table cellpadding="3">
	  <tr style="background-color:#eeeeee">
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
	      <tr style="background-color:#eef8f8">
	    </if>
	    <else>
	      <tr style="background-color:#f8f8ee">
	    </else>
	      <td><strong>@caches.name@</strong></td>
	      <td align="right">@caches.entries@</td>
	      <td align="right">@caches.flushed@</td>
	      <td align="right">@caches.hit_rate@%</td>
	      <td align="right">@caches.size@</td>
	      <td align="right">@caches.max@</td>
	      <td align="center">&nbsp;
	      <a href="flush-cache?suffix=@caches.name@">flush</a>&nbsp;
	      </td>
	    </tr>
	  </multiple>

      </table>

      <form action="show-util-memoize" method=get>
	<div>Show names that contain
	<%
	#<input name="pattern_type" type="radio" value="start">start with
	#<input name="pattern_type" type="radio" value="contain">contain
	%>
	<input name="pattern" type="text" value="">
	<input type="submit" value="Search">
	</div>
      </form>

      <blockquote>
	<div style="color:#994444">Notes:
	<ul>
	  <li>This currently only searches the primary "util_memoize" cache
	</ul>
	</div> 
      </blockquote>

    </blockquote>
