<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>
<property name="head">
<style type="text/css">
td.wide {width:35%;}
</style>
</property>
@dimensional_slider;noquote@

<if @kind@ eq "procs_files">
<blockquote>
<table cellspacing="0" cellpadding="0">
  <multiple name="procs_files">
  <tr valign="top">
    <td class="wide"><strong><a href="@procs_files.view@?version_id=@version_id@&amp;path=@procs_files.full_path@">@procs_files.path@</a></strong></td>
    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
    <td>@procs_files.first_sentence@&nbsp;</td>
  </tr>
  </multiple>
</table>
</blockquote>
</if>
<if @kind@ eq "procs">
<blockquote>
<table cellspacing="0" cellpadding="0">
  <multiple name="procedures">
  <tr valign="top">
    <td class="wide"><strong><a href="proc-view?version_id=@version_id@&amp;proc=@procedures.proc@">@procedures.proc@</a></strong></td>
    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
    <td>@procedures.first_sentence@&nbsp;</td>
  </tr>
  </multiple>
</table>
</blockquote>
</if>
<if @kind@ eq "sql_files">
<blockquote>
<table cellspacing="0" cellpadding="0">
  <multiple name="sql_files">
  <tr valign="top">
    <td><strong><a href="display-sql?package_key=@package_key@&amp;url=@sql_files.relative_path@&amp;version_id=@version_id@">@sql_files.path@</a></strong></td>
    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  </multiple>
</table>
</blockquote>
</if>
<if @kind@ eq "content">
<table cellspacing="0" cellpadding="0">
  <multiple name="content_pages">
  <tr valign="top">
    <if @content_pages.content_type@ eq "page">
      <td class="wide">@content_pages.indentation;noquote@
       <strong><a href="content-page-view?version_id=@version_id@&amp;path=@content_pages.full_path@">@content_pages.name@</a></strong>
       <if @content_pages.type@ ne "">
         <a href="type-view?type=@content_pages.type@"></a>
       </if>
      </td>
      <td>@content_pages.first_sentence@</td>
    </if>
    <if @content_pages.content_type@ eq "directory">
      <td>@content_pages.indentation;noquote@<strong>@content_pages.name@/</strong></td>
    </if>
  </tr>
  </multiple>
</table>
</if>
