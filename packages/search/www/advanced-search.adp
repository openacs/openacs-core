<master>
<property name="title">#search.Advanced_Search#</property>
<property name="context">"advanced search"</property>

<form method=GET action=search>
<input type=text name=q size=41 maxlength=256 value="@q@">
<input type=submit value="Search" name=t>
<br>
#search.Date_Range#
<select name=dfs>
  <option value=all> #search.anytime#
  <option value=m3> #search.past_3_months#
  <option value=m6> #search.past_6_months#
  <option value=y1> #search.past_year#
</select>
#search.nbspDisplay#
<select name=num>
 <option value=10 <if @num@ eq 10>#search.selected#</if>>10 #search.results#
 <option value=20 <if @num@ eq 20>#search.selected#</if>>20 #search.results#
 <option value=30 <if @num@ eq 30>#search.selected#</if>>30 #search.results#
 <option value=50 <if @num@ eq 50>#search.selected#</if>>50 #search.results#
 <option value=100 <if @num@ eq 100>#search.selected#</if>>100 #search.results#
</select>
</form>

