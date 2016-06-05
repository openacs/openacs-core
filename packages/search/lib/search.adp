<form method="GET" action="@search_url@" class="inline-form">
  <div>
    <input type="text" name="q" title="#search.Enter_keywords_to_search_for#" size="16" maxlength="256">
    <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>
    <input type="submit" value="#acs-kernel.common_search#" name="t">
    <br>
    <a href="@advanced_search_url@">#search.Advanced_Search#</a>
  </div>
</form>

