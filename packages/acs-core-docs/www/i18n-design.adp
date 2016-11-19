
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Design Notes}</property>
<property name="doc(title)">Design Notes</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="i18n-convert" leftLabel="Prev"
		    title="
Chapter 14. Internationalization"
		    rightLink="i18n-translators" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="i18n-design" id="i18n-design"></a>Design Notes</h2></div></div></div><p>User locale is a property of ad_conn, <code class="computeroutput">ad_conn locale</code>. The request processor sets
this by calling <code class="computeroutput">lang::conn::locale</code>, which looks for the
following in order of precedence:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Use user preference for this package (stored in
ad_locale_user_prefs)</p></li><li class="listitem"><p>Use system preference for the package (stored in
apm_packages)</p></li><li class="listitem"><p>Use user&#39;s general preference (stored in
user_preferences)</p></li><li class="listitem"><p>Use Browser header (<code class="computeroutput">Accept-Language</code> HTTP header)</p></li><li class="listitem"><p>Use system locale (an APM parameter for acs_lang)</p></li><li class="listitem"><p>default to en_US</p></li>
</ol></div><p>For ADP pages, message key lookup occurs in the templating
engine. For Tcl pages, message key lookup happens with the
<code class="computeroutput">_</code> function. In both cases, if
the requested locale is not found but a locale which is the default
for the language which matches your locale&#39;s language is found,
then that locale is offered instead.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="i18n-convert" leftLabel="Prev" leftTitle="How to Internationalize a Package"
		    rightLink="i18n-translators" rightLabel="Next" rightTitle="Translator&#39;s Guide"
		    homeLink="index" homeLabel="Home" 
		    upLink="i18n" upLabel="Up"> 
		