<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML lang="en">
<HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>@title@</title>

<script language="JavaScript" type="text/javascript">
if (navigator.appName == "Netscape"){
      if (navigator.appVersion.indexOf ("5.0") != -1) {
              document.writeln ('<LINK REL="StyleSheet" HREF="/templates/css/oacs_ns6.css" type="text/css">');
      }
      else {
              document.writeln ('<LINK REL="StyleSheet" HREF="/templates/css/oacs_ns4.css" type="text/css">');
      }
}
else {
document.writeln ('<LINK REL="StyleSheet" HREF="/templates/css/oacs_ie5.css" type="text/css">');
}
</script>

<noscript>
<LINK REL="stylesheet" HREF="/templates/css/oacs_all.css" type="text/css">
</noscript>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">
@header_stuff@
</HEAD>

<BODY BGCOLOR="#ffffff" link="#006699" alink="#0066cc" vlink="#003399" 
style="margin:18px">


<!-- BEGIN header -->
<!-- _______________ BEGIN NAV BAR TABLE _________________  -->

<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<TR>

<if @top_dir@ eq "">
<td align="center" valign="middle" bgcolor="#cccccc" width="8%"><span class="navon">
<if @urlc@ gt 1><a href="/" class="on">home</a></if><else>home</else></span></td>
</if>
<else>
<td align="center" valign="middle" bgcolor="#66ccff" width="8%"><span class="nav">
<a href="/" class="top">home</a></span></td>
</else>


<if @top_dir@ eq "news">
<td align="center" valign="middle" bgcolor="#cccccc" width="18%"><span class="navon">
<if @urlc@ gt 1><a href="/news" class="on">news&amp;events</a></if><else>news&amp;events</else></span></td>
</if>
<else>
<td align="center" valign="middle" bgcolor="#66ccff" width="18%"><span class="nav">
<a href="/news" class="top">news&amp;events</a></span></td>
</else>


<if @top_dir@ eq "community">
<td align="center" bgcolor="#cccccc" valign="middle" width="26%"><span class="navon">
<if @urlc@ gt 1><a class="on" href="/community">forums&amp;community</a></if><else>forums&amp;community</else></span></td>
</if>
<else>
<td align="center" valign="middle" bgcolor="#66ccff" width="26%"><span class="nav">
<a href="/community" class="top">forums&amp;community</a></span></td>
</else>


<if @top_dir@ eq "software">
<td align="center" valign="middle" bgcolor="#cccccc" width="18%"><span class="navon">
<if @urlc@ gt 1><a href="/software" class="on">software</a></if><else>software</else></span></td>
</if>
<else>
<td align="center" valign="middle" bgcolor="#66ccff" width="18%"><span class="nav">
<a href="/software" class="top">software</a></span></td>
</else>


<if @top_dir@ eq "doc">
<td align="center" valign="middle" bgcolor="#cccccc" width="18%"><span class="navon">
<if @urlc@ gt 1><a href="/doc" class="on">documentation</a></if><else>documentation</else></span></td>
</if>
<else>
<td align="center" valign="middle" bgcolor="#66ccff" width="18%"><span class="nav">
<a href="/doc" class="top">documentation</a></span></td>
</else>


<if @top_dir@ eq "pvt">
<td align="center" valign="middle" bgcolor="#cccccc" width="17%"><span class="navon">
<if @urlc@ gt 1><a href="/pvt/home" class="on">my workspace</a></if><else>my workspace</else></span></td>
</if>
<else>
<td align="center" valign="middle" bgcolor="#66ccff" width="17%"><span class="nav">
<a href="/pvt/home" class="top">my workspace</a></span></td>
</else>

</tr>
<tr>
<td align="right" valign="top" colspan="6" bgcolor="#999999"><img src="/templates/images/spacer.gif" 
alt="" height="2" width="1"></td>
</tr>
<tr>
<td align="left" valign="top" colspan="6" bgcolor="#ffffff"><img src="/templates/images/spacer.gif" 
alt="" height="8" width="1"></td>
</tr>
</table>

<!-- _______________ END NAV TABLE __________________________ --> 
<!-- ________________________________________________________ -->

<!-- _______________START LOGO AND LOG IN ROW_______________  -->


<table cellpadding=0 cellspacing=0 width="100%" border=0>
<tr>
<td align="left" valign="top"><a href="/">
<img src="/templates/images/oacs_logo2.jpg" alt="OPEN ACS" 
height="80" width="184" border="0"></a></td>

<td align="center" valign="top">&nbsp;<span class="light">@n_registered_users@ registered users</span></td>

<td align="center" valign="top">

<!-- ____________________ SEARCH AREA ____________________ -->

<form>
<table cellpadding=0 cellspacing=0 border=0>
<tr>

<td align="center" valign="top">
<span class="light">search site&gt;&gt; </span></td>

<td align="center" valign="top"><input type="text" size=12>&nbsp;</td>

<td align="center" valign="top"><input type="submit" value="go" class="button"></td>

</tr>
<tr>
<td colspan=3>
<!-- ____________________  d o w n l o a d  O A C S  l i n k  ____________________-->

<img src="/templates/images/spacer.gif" width="1" height="12" alt=""><br clear="left">
<if @top_dir@ eq "">
<a href="/software/"><span class="blue">&gt;&gt;download OpenACS
</span></a>
</if>
&nbsp;&nbsp</td>
</tr>
</table>
</form>
<!-- ____________________ END SEARCH AREA ____________________ -->
</td>


<td align="right" valign="top">

<!-- ________ IF LOGGED IN, SHOW NAME AT FAR RIGHT ___________ -->
<if @user_name@ not nil>
<form>
<table cellpadding=0 cellspacing=0 border=0>
<tr>
<td align="left" valign="top" colspan="4">
<img src="/templates/images/spacer.gif" alt="" width=1 height=1></td>
</tr>

<tr>
<td align="right"><nobr><span class="light">&nbsp;logged in as @user_name@</span></nobr></td>

<td align="right"><span class="light">&nbsp;&nbsp;|&nbsp;&nbsp;</span></td>

<td align="right"><a href="/register/logout"><span class="light">log&nbsp;out</span></a></td>
<td align="right">&nbsp;</td>

</tr>
</table>
</form>
</if>
<else>


<!-- SHOW LOG IN FIELDS -->

<if @top_dir@ ne "register">
<FORM method=post action="/register/user-login">

@form_vars@
<table cellpadding=0 cellspacing=0 border=0>
<tr>

<td align="right" valign="top">
<span class="light">email:&nbsp;</span></td>

<td align="left" valign="top">
<INPUT type="text" name="email" tabindex="1" value="@email@"></td>

<td valign="top" align="left">&nbsp;<input type="submit" value="log in" class="button" tabindex="3">&nbsp;
</td>
</tr>

<tr>
<td align="right" valign="top"><span class="light">password:&nbsp;</span></td>

<td align="left" valign="top"><input type="password" name="password" tabindex="2"></td>

<td valign="top" align="left">
<span class="light">
&nbsp;<input type=checkbox name=persistent_cookie_p value=1 checked>
save?
<a href="/register/explain-persistent-cookies">(more)</a>
</td>

</tr>
</table>

</form>
</if> <!-- not on register page-->

</else>
<!-- __________ END LOG IN and USER NAME ____________ -->
</td>
</tr>
</table>

<table Cellpadding=0 cellspacing=0 border=0>
<tr>
<td align="left" valign="top" bgcolor="#ffffff"><img src="/templates/images/spacer.gif" alt="" height="1" width="1"></td>
</tr>
</table>
<!-- ________ END HEADER  ___________ -->

<h3>
Hi all! This site is undergoing a migration from <a href="http://openacs.org">The current OpenACS.org</a>. Feel free to log in if you are curious. Your current openacs.org account should work just fine.
<br>
<br>
We (Roberto Mello, Dave Bauer, Ola Hansson) expect to be ready with the main migration by August 12.
</h3>

<slave>
<br><br>
<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>
<td align="LEFT" valign="top" bgcolor="#999999" colspan="2"><img src="/templates/images/spacer.gif" alt="" height="1" width="1"></td>
</tr>
<tr>
<td align="LEFT" valign="top" colspan="2"><img src="/templates/images/spacer.gif" alt="" height="6" width="1"></td>
</tr>
<tr>
<td align="left" valign="top"><span class="small">This site is 
maintained by the Open ACS Community. 
Any problems, email <a href="mailto:webmaster@openacs.org">webmaster@openacs.org</a>.<br></SPAN></TD>

<TD ALIGN="RIGHT" width="100">
<if @etp_link@ not nil><span class="small">
<b>@etp_link@;noquote</b></span>
</if>
</td>
</TR>
</TABLE>

</body>
</html>
