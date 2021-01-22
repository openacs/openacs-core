
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Laying out a page with CSS instead of tables}</property>
<property name="doc(title)">Laying out a page with CSS instead of tables</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-vuh" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-html-email" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-css-layout" id="tutorial-css-layout"></a>Laying out a page with CSS instead of
tables</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592101677160" id="idp140592101677160"></a>.LRN home page with table-based
layout</h3></div></div></div><div class="mediaobject" align="center"><img src="images/dotlrn-style-1.png" align="middle"></div><p>A sample of the HTML code (<a class="ulink" href="files/dotlrn-style-1" target="_top">full source</a>)</p><pre class="programlisting">
&lt;table border="0" width="100%"&gt;
  &lt;tr&gt;
    &lt;td valign="top" width="50%"&gt;
      &lt;table class="element" border="0" cellpadding="0" cellspacing="0" width="100%"&gt;
        &lt;tr&gt; 
          &lt;td colspan="3" class="element-header-text"&gt;
            &lt;bold&gt;Groups&lt;/bold&gt;
         &lt;/td&gt;
       &lt;/tr&gt;
       &lt;tr&gt;
         &lt;td colspan="3" class="dark-line" height="0"&gt;&lt;img src="/resources/acs-subsite/spacer.gif"&gt;&lt;/td&gt;&lt;/tr&gt;
          &lt;tr&gt;
            &lt;td class="light-line" width="1"&gt;
              &lt;img src="/resources/acs-subsite/spacer.gif" width="1"&gt;
            &lt;/td&gt;
            &lt;td class="element-text" width="100%"&gt;
            &lt;table cellspacing="0" cellpadding="0" class="element-content" width="100%"&gt;
              &lt;tr&gt;
                &lt;td&gt;
                  &lt;table border="0" bgcolor="white" cellpadding="0" cellspacing="0" width="100%"&gt;
                    &lt;tr&gt;
                      &lt;td class=element-text&gt;
                        MBA 101
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140592101682168" id="idp140592101682168"></a>.LRN Home with CSS-based layout</h3></div></div></div><div class="mediaobject" align="center"><img src="images/dotlrn-style-3.png" align="middle"></div><p>A sample of the HTML code (<a class="ulink" href="files/dotlrn-style-2" target="_top">full source</a>)</p><pre class="programlisting">
&lt;div class="left"&gt;
  &lt;div class="portlet-wrap-shadow"&gt;
    &lt;div class="portlet-wrap-bl"&gt;
      &lt;div class="portlet-wrap-tr"&gt;
        &lt;div class="portlet"&gt;
          &lt;h2&gt;Groups&lt;/h2&gt;
          &lt;ul&gt;
            &lt;li&gt;
              &lt;a href="#"&gt;Class MBA 101&lt;/a&gt;
</pre><p>If the CSS is removed from the file, it looks somewhat
different:</p><div class="mediaobject" align="center"><img src="images/dotlrn-style-2.png" align="middle"></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-vuh" leftLabel="Prev" leftTitle="Using .vuh files for pretty urls"
		    rightLink="tutorial-html-email" rightLabel="Next" rightTitle="Sending HTML email from your
application"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		