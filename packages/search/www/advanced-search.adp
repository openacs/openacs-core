<master>
<property name="doc(title)">#search.Advanced_Search#</property>
<property name="context">"advanced search"</property>

<div>
<form method="GET" action="search">
<p>
<input type="text" name="q" size="41" maxlength="256" value="@q@">
<input type="submit" value="Search" name="t">
<if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
</p>
<p>
<label for="dfs">#search.Date_Range#</label>
<select id="dfs" name=dfs>
  <option value=all> #search.anytime#
  <option value=m3> #search.past_3_months#
  <option value=m6> #search.past_6_months#
  <option value=y1> #search.past_year#
</select>
<label for="num">#search.nbspDisplay#</label>
<select id="num" name=num>
 <option value=10 <if @num@ eq 10>#search.selected#</if>>10 #search.results#
 <option value=20 <if @num@ eq 20>#search.selected#</if>>20 #search.results#
 <option value=30 <if @num@ eq 30>#search.selected#</if>>30 #search.results#
 <option value=50 <if @num@ eq 50>#search.selected#</if>>50 #search.results#
 <option value=100 <if @num@ eq 100>#search.selected#</if>>100 #search.results#
</select>
</p>
</form>
</div>
