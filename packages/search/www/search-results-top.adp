<html>
<head>
   <title>@title@</title>
</head>
<body bgcolor=ffffff text=000000 >
<h2>@title@</h2>
@context_bar@

<table border=0 cellpadding=3 cellspacing=0 leftmargin=15 topmargin=5 marginwidth=15 marginheight=5>
  <tr><td nowrap>
    <form method=GET action=search>
      <small>
        <input type=text name=q size=31 maxlength=256 value="@query@">
        <input type=submit value=Search>
      </small>
    </form>
  </td></tr>
<if @and_queries_notice_p@ eq 1>
  <tr><td>
    <small>
      <font color=6f6f6f>
        The "<b>AND</b>" operator is unnecessary -- we include all search terms by default. 
        [<a href=help/basics#and>details</a>]
      </font>
    </small>
  </td></tr>
</if>
<if @nstopwords@ eq 1>
  <tr><td>
    <small>
      <font color=6f6f6f>
        "<b>@stopwords@</b>" is a very common word and was not included in your search.
        [<a href=help/basics#stopwords>details</a>]
      </font>
    </small>
  </td></tr>
</if>
<if @nstopwords@ gt 1>
  <tr><td>
    <small>
      <font color=6f6f6f>
        The following words are very common and were not included in your search: <b>@stopwords@</b>.
        [<a href=help/basics#stopwords>details</a>]
      </font>
    </small>
  </td></tr>
</if>
</table>

<if @count@ eq 0>
  <br><br>Your search - <b>@query@</b> - did not match any documents.
  <br>No pages were found containing "<b>@query@</b>".
  <br><br>Suggestions:
  <ul>
    <li>Make sure all words are spelled correctly.
    <li>Try different keywords.
    <li>Try more general keywords.
    <if @nquery@ gt 2>
      <li>Try fewer keywords.
    </if>
  </ul>
</if>
<else>
  <br>
  <table width=100% bgcolor=3366cc border=0 cellpadding=3 cellspacing=0>
    <tr><td>
      <font color=white>
        Searched for: @query@
      </font>
    </td><td align=right>
      <font color=white>
        Results <b>@low@-@high@</b> of about <b>@count@</b>.
        Search took <b>@elapsed@</b> seconds. 
      </font>     
    </td></tr>
  </table>
  <br clear=all>
</else>

<slave>