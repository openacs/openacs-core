<master>
<property name="doc(title)">#search.Search#</property>

<div style="text-align:center">
<form method="GET" action="search">
  <div><small><a href="advanced-search">#search.Advanced_Search#</a></small></div>
  <div>
  <input type="text" name="q" size="80" maxlength="256">
  <br>
  <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
  <input type="submit" value="#search.Search#" name="t">
  <input type="submit" value="#search.Feeling_Lucky#" name="t">
  </div>
</form>
</div>
