<master>
<property name="title">Advanced Search</property>
<property name="context">"advanced search"</property>


<form method=GET action=search>
<input type=text name=q size=41 maxlength=256 value="@q@">
<input type=submit value="Search" name=t>
<br>
Date Range
<select name=dfs>
  <option value=all> anytime
  <option value=m3> past 3 months
  <option value=m6> past 6 months
  <option value=y1> past year
</select>
&nbsp;Display
<select name=num>
 <option value=10 <if @num@ eq 10>selected</if>>10 results
 <option value=20 <if @num@ eq 20>selected</if>>20 results
 <option value=30 <if @num@ eq 30>selected</if>>30 results
 <option value=50 <if @num@ eq 50>selected</if>>50 results
 <option value=100 <if @num@ eq 100>selected</if>>100 results
</select>
</form>
