
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Using Form Builder: building html forms dynamically}</property>
<property name="doc(title)">Using Form Builder: building html forms dynamically</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="programming-with-aolserver" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="eng-standards" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="form-builder" id="form-builder"></a>Using Form Builder: building html forms
dynamically</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="ad-form-overview" id="ad-form-overview"></a>Overview</h3></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red"><span class="cvstag">($&zwnj;Id:
form-builder.xml,v 1.10 2017/08/07 23:47:54 gustafn Exp
$)</span></span></p>
&lt;/authorblurb&gt;
<p>OpenACS has a form manager called ad_form. Ad_form has an
adaptable UI. Error handling includes inline error reporting, and
is customizable. However, ad_form can be tricky to use. In addition
to this document, the ad_form <a class="ulink" href="http://openacs.org/api-doc/proc-view?proc=ad_form" target="_top">api documentation</a> is helpful.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="multi-part-elements" id="multi-part-elements"></a>Multi-part Elements</h3></div></div></div><p>Some elements have more than one choice, or can submit more than
one value.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682187815384" id="idp140682187815384"></a>SELECT elements</h4></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1"><li class="listitem">
<p>
<strong>Creating the form element. </strong> Populate a
list of lists with values for the option list.</p><pre class="programlisting">
set foo_options [db_list_of_lists foo_option_list "
    select foo,
           foo_id
      from foos
"]
</pre><p>The variable <code class="computeroutput">foo_options</code>
should resemble <code class="computeroutput">{{first foo} 1234}
{{second foo} 1235}</code>
</p><p>Within ad_form, set up the element to use this list:</p><pre class="programlisting">{foo:text(select)
        {label "Which Foo"}
        {options $foo_options}
    }</pre><p>This will result in a single name/value pair coming back in the
submitted form. Handle this within the same ad_form structure, in
the <code class="computeroutput">-new_data</code> and <code class="computeroutput">-edit_data</code>. In the example, it is available
as <code class="computeroutput">$foo</code>
</p>
</li></ol></div><p>See also the <a class="ulink" href="http://www.w3.org/TR/html401/interact/forms.html#h-17.6" target="_top">W3C spec for "The SELECT, OPTGROUP, and OPTION
elements"</a>.</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="refreshing" id="refreshing"></a>Using
refreshes to pull additional information from the database</h3></div></div></div><p>A situation you may run into often is where you want to pull in
form items from a sub-category when the first category is selected.
Ad_form makes this fairly easy to do. In the definition of your
form element, include an html section</p><pre class="programlisting">
{pm_task_id:integer(select),optional
        {label "Subject"}
        {options {$task_options}}
        {html {onChange "document.form_name.__refreshing_p.value='1';submit()"}}
        {value $pm_task_id}
    }
    </pre><p>What this will do is set the value for pm_task_id and all the
other form elements, and resubmit the form. If you then include a
block that extends the form, you&#39;ll have the opportunity to add
in subcategories:</p><pre class="programlisting">
if {[info exists pm_task_id] &amp;&amp; $pm_task_id ne ""} {
    db_1row get_task_values { }
    ad_form -extend -name form_name -form { ... }
    </pre><p>Note that you will get strange results when you try to set the
values for the form. You&#39;ll need to set them explicitly in an
-on_refresh section of your ad_form. In that section, you&#39;ll
get the values from the database, and set the values as so:</p><pre class="programlisting">    db_1row get_task_values { }
    template::element set_value form_name estimated_hours_work $estimated_hours_work
    </pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="form-troubleshooting" id="form-troubleshooting"></a>Troubleshooting</h3></div></div></div><p>A good way to troubleshoot when you&#39;re using ad_form is to
add the following code at the top of the .tcl page (thanks Jerry
Asher):</p><pre class="programlisting">
ns_log notice it&#39;s my page!
set mypage [ns_getform]
if {$mypage eq ""} {
    ns_log notice no form was submitted on my page
} else {
    ns_log notice the following form was submitted on my page
    ns_set print $mypage
}
    </pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="form-widgets" id="form-widgets"></a>Tips
for form widgets</h3></div></div></div><p>Here are some tips for dealing with some of the form
widgets:</p><p><a class="ulink" href="http://openacs.org/forums/message-view?message_id=106331" target="_top">Current widget</a></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="errors" id="errors"></a>Common
Errors</h3></div></div></div><p>Here are some common errors and what to do when you encounter
them:</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140682187269320" id="idp140682187269320"></a>Error when selecting values</h4></div></div></div><p>This generally happens when there is an error in your query.</p>
</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="programming-with-aolserver" leftLabel="Prev" leftTitle="Programming with AOLserver"
			rightLink="eng-standards" rightLabel="Next" rightTitle="Chapter 12. Engineering
Standards"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    