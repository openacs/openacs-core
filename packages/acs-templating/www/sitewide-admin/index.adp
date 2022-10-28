<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<h1>@title;noquote@</h1>

<h4>Support for the adp:icon Tag</h4>
<p>Font Awesome Icons can be used via adp:icons can be used on ADP pages with
    <blockquote class="mx-4">
    <code>&lt;adp:icon name="<i>NAME</i>" title="..." style="..." class="..." iconset='...' invisible='...'&gt;</code>
    </blockquote>
    
<p>The last three arguments are optional.
<a href="https://fontawesome.com/search?m=free">Font Awesome Icons</a>
defines in
version 6.1.1 more than 2,000 free icons.  When installing Font Awesome Icons,
all of these are usable independent of the style of the site.

<p>However, when one wants to keep e.g. some subsites in Bootstrap 3
and others in Bootstrap 5, and the classic Bootstrap 3 look-and-feel
should be kept, and the identical markup should adapt its
Look-and-Feel depending on the subsite theme, there are some
restrictions. OpenACS supports the icon sets
<a href="https://openacs.org/doc/acs-subsite/images">"classic"</a>
(old-style gif/png images),
<a href="https://getbootstrap.com/docs/3.4/components/">"glyphicons"</a>
(Part of Bootstrap 3),
<a href="https://icons.getbootstrap.com/">"bootstrap-icons"</a> (usable for all
themes), and
<a href="https://fontawesome.com/search?m=free">"fa-icons"</a> (usable
for all themes).  Some of the icon names are usable via adp:icon for
all OpenACS icon sets, some of these can be used without further
mapping as replacement of the gyphicons of Bootstrap 3.

<p> The names which can be used for all icon sets are called
"generic", since for these, a mapping from the specific icon set to
the generic name exists. See below for lists of names and contexts,
where these can be used.


<p>Defined <strong>generic names</strong> for <code>adp:icons</code>,
working with icon sets
<a href="https://openacs.org/doc/acs-subsite/images">"classic"</a>,
<a href="https://getbootstrap.com/docs/3.4/components/">"glyphicons"</a>,
<a href="https://icons.getbootstrap.com/">"bootstrap-icons"</a>, and
<a href="https://fontawesome.com/search?m=free">"fa-icons"</a>.  This means that the same
name can be used in the markup. When switching the themes/iconset,
different icon sets are used without the need of rewriting any markup.
The current default icon set is <strong>@default_iconset@</strong>.

In the listing below, the glyphicons are only rendered when running
under the bootstrap3 theme.

<blockquote class="mx-4">
  @genericHTML;noquote@
</blockquote>


<include src="/packages/acs-templating/lib/registered-urns" match="*">
