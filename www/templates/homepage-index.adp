<master>
<property name="title">@pa.title@</property>


<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
<!-- left side cell -->
<td align="left" valign="top" width="190">

<!-- nested left side table -->

<TABLE WIDTH="190" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>
<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span 
class="nav"><a href="/features/" class="top">featured articles</a></span></td>

<td align="right" valign="top" bgcolor="#cccccc"><img 
src="/templates/images/greyright.gif" alt="" height="8" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="2"><img 
src="/templates/images/spacer.gif" alt="" height="2" width="182"></td>

<td align="left" valign="top" bgcolor="#cccccc" colspan="2"><img
src="/templates/images/spacer.gif" alt="" height="2" width="8"></td>
</tr>
<tr>

<td align="left" valign="top" bgcolor="#dedede"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#dedede">
<br>
<span class="small">
<multiple name=feature_items>
<!--maxrows doesn't take a variable value, so have to do this-->
<if @feature_items.rownum@ le @n_feature_items@>
  <a href="@feature_items.url@" class="top"><b>@feature_items.title@:</b></a><br>
  @feature_items.description@<br>
  <img src="/templates/images/spacer.gif" alt="" height="8" width="174">
  <br clear="left">
</if>
</multiple>

<if @feature_items:rowcount@ gt @n_feature_items@>
<br>
<a href="/features">more articles...</a><br>
</if>
</span>
</td>
<td align="left" valign="top" bgcolor="#cccccc"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>

<tr>
<td align="left" valign="top" bgcolor="#cccccc" colspan="3"><img
src="/templates/images/grey.gif" alt="" height="8" width="8"></td>
</tr>

</table>
</td>
<!-- end left side cell -->

<!-- MARGIN -->
<td align="left" valign="top" width="30"><img src="/templates/images/spacer.gif" alt="" 
height="1" width="30"></td>


<!-- main text area - MAIN TEXT -->
<td align="left" valign="top" width="100%">
<span>@pa.content@</span>
</td>

<!-- MARGIN -->
<td align="right" valign="top" width="30">
<img src="/templates/images/spacer.gif" alt=""
height="1" width="30"></td>

<!-- right side cell -->
<td align="right" valign="top" width="190">

<!-- nested right side table -->

<TABLE width="190" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>

<td align="left" valign="top" bgcolor="#66ccff" width="8"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff" width="174">
<span class="nav"><a href="/forums/" class="top">
forums</a>: recent posts</span></td>

<td align="right" valign="top" bgcolor="#cccccc" width="8"><img 
src="/templates/images/greyright.gif" alt="" height="8" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="2"><img 
src="/templates/images/spacer.gif" alt="" height="2" width="182"></td>

<td align="left" valign="top" bgcolor="#cccccc" width="8"><img
src="/templates/images/spacer.gif" alt="" height="2" width="8"></td>
</tr>
<tr>

<td align="left" valign="top" bgcolor="#dedede" width="8"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#dedede" width="174">
<img src="/templates/images/spacer.gif" alt="" height="8" width="174"><br clear="left">

<br>
<span class="small">
<multiple name=forum_posts>
<if @forum_posts.rownum@ le @n_forum_posts@>
  <a href="/forums/forum-view?forum_id=@forum_posts.forum_id@" class="top"><b>@forum_posts.forum_name@</b></a>:<br>

<group column="forum_id">
  <li><a href="/forums/message-view?message_id=@forum_posts.message_id@">@forum_posts.title@</a></li>
</group>

  <img src="/templates/images/spacer.gif" alt="" height="8" width="174">
  <br clear="left">

</if>
</multiple>

<if @forum_posts:rowcount@ gt @n_forum_posts@>
<a href="/forums">more posts...</a>
</if>
<p>

</span></td>



<td align="left" valign="top" bgcolor="#cccccc" width="8"><img 
src="/templates/images/spacer.gif" alt="" height="8" width="8"></td>

</tr>

<tr>
<td align="left" valign="top" bgcolor="#cccccc" colspan="3" width="190"><img
src="/templates/images/grey.gif" alt="" height="8" width="8"></td>
</tr>

<tr>
<td align="left" valign="top" bgcolor="#ffffff" colspan="3"><img 
src="/templates/images/spacer.gif" alt="" height="15" width="190"></td>
</tr>

<tr>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span 
class="nav"><a href="/news" class="top">news</a></span></td>

<td align="right" valign="top" bgcolor="#cccccc"><img 
src="/templates/images/greyright.gif" alt="" height="8" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="2"><img 
src="/templates/images/spacer.gif" alt="" height="2" width="182"></td>

<td align="left" valign="top" bgcolor="#cccccc" colspan="1"><img
src="/templates/images/spacer.gif" alt="" height="2" width="8"></td>
</tr>
<tr>

<td align="left" valign="top" bgcolor="#dedede"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#dedede">
<img src="/templates/images/spacer.gif" alt="" height="8" width="174"><br clear="left">

<span class="reg">

<multiple name=news_items>
<!--maxrows doesn't take a variable value, so have to do this-->
<if @news_items.rownum@ le @n_news_items@>
  <b>@news_items.pretty_publish_date@</b>:<br>
  <a href="/news/item?item_id=@news_items.item_id@">@news_items.publish_title@</a><br>
  <img src="/templates/images/spacer.gif" alt="" height="8" width="174">
  <br clear="left">
</if>
</multiple>

<if @news_items:rowcount@ gt @n_news_items@>
<br>
<a href="/news">more news...</a><br>
</if>
</span>
</td>

<td align="left" valign="top" bgcolor="#cccccc"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>

<tr>
<td align="left" valign="top" bgcolor="#cccccc" colspan="3"><img
src="/templates/images/grey.gif" alt="" height="8" width="8"></td>
</tr>

</table>
</td>
<!-- end right side cell -->
</tr>
</table>








