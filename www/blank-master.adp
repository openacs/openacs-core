<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta name="generator" content="OpenACS version @openacs_version@" />
    <title>@title;noquote@</title>
    <multiple name="header_links">
      <link rel="@header_links.rel@" type="@header_links.type@"
      href="@header_links.href@" media="@header_links.media@" />
    </multiple>

    <if @acs_blank_master__htmlareas@ not nil>
      <script type="text/javascript" src="/resources/acs-templating/htmlarea/htmlarea.js"></script>
      <script type="text/javascript" src="/resources/acs-templating/htmlarea/lang/en.js"></script>
      <script type="text/javascript" src="/resources/acs-templating/htmlarea/dialog.js"></script>

      <style type="text/css">
      @import url(/resources/acs-templating/htmlarea/htmlarea.css);
      </style>
    </if>

    <script type="text/javascript" src="/resources/acs-subsite/core.js" language="javascript"></script>

    @header_stuff;noquote@
  </head>
  <body<multiple name="attribute"> @attribute.key@="@attribute.value@"</multiple>>

    <textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea>
    <if @dotlrn_toolbar_p@ true>
      <include src="/packages/dotlrn/lib/toolbar">
    </if>
    <if @developer_support_p@ true>
      <include src="/packages/acs-developer-support/lib/toolbar">
    </if>

    <slave>

    <if @developer_support_p@ true>
      <include src="/packages/acs-developer-support/lib/footer">
    </if>
    <if @translator_mode_p@ true>
      <include src="/packages/acs-lang/lib/messages-to-translate">
    </if>
  </body>
</html>
