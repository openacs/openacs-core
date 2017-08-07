
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Translator&#39;s Guide}</property>
<property name="doc(title)">Translator&#39;s Guide</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="i18n-design" leftLabel="Prev"
		    title="
Chapter 14. Internationalization"
		    rightLink="cvs-tips" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="i18n-translators" id="i18n-translators"></a>Translator&#39;s Guide</h2></div></div></div><p>Most translators use the <a class="ulink" href="http://translate.openacs.org" target="_top">OpenACS Public
Translation Server</a>, because the process of getting new message
keys onto the server and getting new translations back into the
distribution are handled by the maintainers of that machine. You
can also do translation work on your own OpenACS site; this makes
your own translations more readily available to you but also means
that your work will not be shared with other users unless you take
extra steps (contacting an OpenACS core developer or submitting a
patch) to get your work back to the OpenACS core.</p><p>The basic steps for translators:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Go to the <a class="ulink" href="/acs-lang" target="_top">Localization</a> page and choose the locale that you are
translating to. If the locale is not present you need to visit
<a class="ulink" href="/acs-lang/admin" target="_top">Administration of Localization</a> and create the
locale.</p></li><li class="listitem">
<p>
<strong>Translating with Translator
Mode. </strong>To translate messages in the pages they
appear, <a class="ulink" href="http://localhost:8008/acs-lang/admin/translator-mode-toggle" target="_top">Toggle Translator Mode</a> and then browse to the
page you want to translate. Untranslated messages will have a
yellow background and a red star that you click to translate the
message. Translated messages have a green star next to them that is
a hyperlink to editing your translation. There is a history
mechanism that allows you to see previous translations in case you
would want to revert a translation.</p><div class="mediaobject" align="center"><img src="images/translator-mode.png" align="middle"></div><p>While in Translator mode, a list of all message keys appears at
the bottom of each page.</p><div class="mediaobject" align="center"><img src="images/translations.png" align="middle"></div>
</li><li class="listitem">
<p>
<strong>Batch translation. </strong>To translate
many messages at once, go to <a class="ulink" href="/acs-lang/admin" target="_top">Administration of Localization</a>,
click on the locale to translate, then click on a package, and then
click <code class="computeroutput">Batch edit these
messages</code>.</p><div class="mediaobject" align="center"><img src="images/translation-batch-edit.png" align="middle"></div>
</li>
</ul></div><p>When creating a new locale based on an existing one, such as
creating the Guatemalan version of Spanish, you can copy the
existing locale&#39;s catalog files using the script <code class="computeroutput">/packages/acs-core-docs/www/files/create-new-catalog.sh</code>.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="i18n-design" leftLabel="Prev" leftTitle="Design Notes"
		    rightLink="cvs-tips" rightLabel="Next" rightTitle="
Appendix D. Using CVS with an OpenACS
Site"
		    homeLink="index" homeLabel="Home" 
		    upLink="i18n" upLabel="Up"> 
		