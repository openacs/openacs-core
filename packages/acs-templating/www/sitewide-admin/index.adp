<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<h1>@title;noquote@</h1>

<h4>Support for the adp:icon Tag</h4>
<p>The adp:icon can be used as followed:
    <blockquote class="mx-4">
    <code>&lt;adp:icon name="<i>NAME</i>" title="..." style="..." class="..." iconset='...' invisible='...'&gt;</code>
    </blockquote>
    
<p>The current version of OpenACS supports the 4 icon sets
<a href="https://openacs.org/doc/acs-subsite/images">"classic"</a>
(old-style gif/png images),
<a href="https://getbootstrap.com/docs/3.4/components/">"glyphicons"</a>
(Part of Bootstrap 3),
<a href="https://icons.getbootstrap.com/">"bootstrap-icons"</a> (usable for all
themes), and
<a href="https://fontawesome.com/search?m=free">"fa-icons"</a> (usable
for all themes).  

<p> The generic icon names can be used for all icon sets, since for
these, a mapping from the specific icon set to the generic name
exists. When using adp:icon with a generic name, the themes/iconset
causes different icons to be used, without requiring you to rewrite
any markup.

<p>In the listing below, the glyphicons are only rendered when running
under the bootstrap3 theme.  The current default icon set is
<strong>@default_iconset@</strong>.


<blockquote class="mx-4">
  @genericHTML;noquote@
</blockquote>


<include src="/packages/acs-templating/lib/registered-urns" match="*">
