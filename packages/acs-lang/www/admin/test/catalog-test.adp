<%
    ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=iso-8859-1"	
%>
@header@
<h3>@title@</h3>
@context_bar@
<hr>
<p>
[ad_locale user locale] ==> @locale@
<br>
[ad_locale user language] ==> @language@
<br>
[ad_locale_language_name @language@] ==> @language_name@
<p>


<strong>Test 1</strong>
<p>
<em>Verify that the message catalog loader ran
successfully at server startup.</em>
<p>
<table cellspacing="0" cellpadding="4" border="1">
<tr><th>Word to lookup</th><th>Language</th><th>Results of catalog lookup</th></tr>
<tr><td>English</td><td>English</td><td>@english@</td></tr>
<tr><td>French</td><td>French</td><td>@french@</td></tr>
<tr><td>Spanish</td><td>Spanish</td><td>@spanish@</td></tr>
<tr><td>German</td><td>German</td><td>@german@</td></tr>
</table>
<p>

<strong>Test 2</strong>
<p>
<em>Verify that the &lt;trn&gt; ADP tag works when the user's preferred
language is set to 
<a href="locale-set?locale=en_US">English</a>,
<a href="locale-set?locale=fr_FR">French</a>,
<a href="locale-set?locale=es_ES">Spanish</a>,
or <a href="locale-set?locale=de_DE">German</a></em>.
<p>

Test of inline  adp tags:
<table cellspacing="0" cellpadding="4" border="1">
  <tr>
    <th>Word to lookup</th>
    <th>&lt;TRN&gt;</th>
    <th>\#...#</th>
  </tr>
  <tr>
    <td>English</td>
    <td><trn key="test.English">English</trn></td>
    <td>#test.English#</td>
  </tr>
  <tr>
    <td>French</td>
    <td><trn key="test.French">French</trn></td>
    <td>#test.French#</td>
  </tr>
  <tr>
    <td>Spanish</td>
    <td><trn key="test.Spanish">Spanish</trn></td>
    <td>#test.Spanish#</td>
  </tr>
  <tr>
    <td>German</td>
    <td><trn key="test.German">German</trn></td>
    <td>#test.German#</td></td>
  </tr>
</table>
<p>

@footer@
