
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Internationalization and Localization Overview}</property>
<property name="doc(title)">Internationalization and Localization Overview</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="i18n" leftLabel="Prev"
		    title="
Chapter 14. Internationalization"
		    rightLink="i18n-introduction" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="i18n-overview" id="i18n-overview"></a>Internationalization and Localization
Overview</h2></div></div></div><div class="table">
<a name="i18n-l10n-process" id="i18n-l10n-process"></a><p class="title"><strong>Table 14.1. Internationalization
and Localization Overview</strong></p><div class="table-contents"><table class="table" summary="Internationalization and Localization Overview" cellspacing="0" border="1">
<colgroup>
<col class="step"><col class="description"><col class="who">
</colgroup><thead><tr>
<th>Stage</th><th>Task</th><th>Who</th>
</tr></thead><tbody>
<tr>
<td>Internationalization</td><td>Package Developer uses the acs-lang tools to replace all
visible text in a package with <span class="emphasis"><em>message
keys</em></span>. (<a class="link" href="i18n-introduction" title="How Internationalization/Localization works in OpenACS">More
information</a>)</td><td>Package Developer</td>
</tr><tr>
<td rowspan="2">Release Management</td><td>The newly internationalized package is released.</td><td>Package Developer</td>
</tr><tr>
<td>The translation server is updated with the new package.</td><td>Translation server maintainers</td>
</tr><tr>
<td>Localization</td><td>Translators work in their respective locales to write text for
each message key. (<a class="link" href="i18n-translators" title="Translator&#39;s Guide">More information</a>)</td><td>Translators</td>
</tr><tr>
<td rowspan="3">Release Management</td><td>The translated text in the database of the translation server
is compared to the current translations in the OpenACS code base,
conflicts are resolved, and the new text is written to catalog
files on the translation server.</td><td>Translation server maintainers</td>
</tr><tr>
<td>The catalog files are committed to the OpenACS code base.</td><td>Translation server maintainers</td>
</tr><tr>
<td>A new version of OpenACS core and/or affected packages is
released and published in the OpenACS.org repository.</td><td>Release Manager</td>
</tr><tr>
<td rowspan="2">Upgrading</td><td>Site Administrators upgrade their OpenACS sites, either via the
automatic upgrade from the Repository or via tarball or CVS</td><td>Site Administrators</td>
</tr><tr>
<td>Site Administrators import the new translations. Existing local
translations, if they exist, are not overwritten.</td><td>Site Administrators</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break">
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="i18n" leftLabel="Prev" leftTitle="
Chapter 14. Internationalization"
		    rightLink="i18n-introduction" rightLabel="Next" rightTitle="How Internationalization/Localization
works in OpenACS"
		    homeLink="index" homeLabel="Home" 
		    upLink="i18n" upLabel="Up"> 
		