
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Enabling WYSIWYG}</property>
<property name="doc(title)">Enabling WYSIWYG</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-schedule-procs" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-parameters" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-wysiwyg-editor" id="tutorial-wysiwyg-editor"></a>Enabling
WYSIWYG</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:nima.mazloumi\@gmx.de" target="_top">Nima
Mazloumi</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>Most of the forms in OpenACS are created using the form builder,
see <a class="xref" href="form-builder" title="Using Form Builder: building html forms dynamically">the section
called “Using Form Builder: building html forms dynamically”</a>.
For detailed information on the API take a look <a class="ulink" href="/api-doc/proc-view?proc=ad_form" target="_top">here</a>.</p><p>The following section shows how you can modify your form to
allow WYSIWYG functionalities.</p><p>Convert your page to use <code class="code">ad_form</code> (some
changes but worth it)</p><p>Here an examples. From:</p><pre class="programlisting">
        template::form create my_form
        template::element create my_form my_form_id -label "The ID" -datatype integer -widget hidden
        template::element create my_form my_input_field_1 -html { size 30 } -label "Label 1" -datatype text -optional
        template::element create my_form my_input_field_2 -label "Label 2" -datatype text -help_text "Some Help" -after_html {&lt;a name="#"&gt;Anchor&lt;/a&gt;}
        </pre><p>To:</p><pre class="programlisting">
        ad_form -name my_form -form {
                my_form_id:key(acs_object_id_seq)
                {my_input_field_1:text,optional
               {label "Label 1"}
               {html {size 30}}}
        {my_input_field_2:text
               {label "Label 2"}
               {help_text "Some Help"}
                   {after_html
               {&lt;a name="#"&gt;Anchor&lt;/a&gt;}}}
        } ...
        </pre><div class="warning" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Warning</h3><p>You must not give your form the same name that your page has.
Otherwise HTMLArea won&#39;t load.</p>
</div><p>Convert your textarea widget to a richtext widget and enable
htmlarea.</p><p>The <code class="code">htmlarea_p</code>-flag can be used to
prevent WYSIWYG functionality. Defaults to true if left away.</p><p>From:</p><pre class="programlisting">
        {my_input_field_2:text
        </pre><p>To:</p><pre class="programlisting">
        {my_input_field_2:richtext(richtext)
                        {htmlarea_p "t"}
        </pre><p>The richtext widget presents a list with two elements: text and
content type. To learn more on existing content types search in
Google for "MIME-TYPES" or take a look at the
<code class="code">cr_mime_types</code> table.</p><p>Make sure that both values are passed as a list to your
<code class="code">ad_form</code> or you will have problems
displaying the content or handling the data manipulation
correctly.</p><p>Depending on the data model of your package you either support a
content format or don&#39;t. If you don&#39;t you can assume
<code class="code">"text/html"</code> or <code class="code">"text/richtext"</code> or <code class="code">"text/enhanced"</code>.</p><p>The relevant parts in your <code class="code">ad_form</code>
definition are the switches <code class="code">-new_data</code>,
<code class="code">-edit_data</code>, <code class="code">-on_request</code> and <code class="code">-on_submit</code>.</p><p>To allow your data to display correctly you need to add an
<code class="code">-on_request</code> block. If you have the format
stored in the database pass this as well else use <code class="code">"text/html"</code>:</p><pre class="programlisting">
        set my_input_field_2 [template::util::richtext::create $my_input_field_2 "text/html"]
        </pre><p>Now make sure that your SQL queries that do the data
manipulation retrieve the correct value. If you simply use
<code class="code">my_input_field_2</code> you will store a list.
Thus you need to add an <code class="code">-on_submit</code>
block:</p><pre class="programlisting">
        set my_input_field_2 [ template::util::richtext::get_property contents $my_input_field_2]
        set format [ template::util::richtext::get_property format $my_input_field_2] #This is optional
        </pre><p>Now the correct values for <code class="code">my_input_field_2</code> and <code class="code">format</code>
are passed to the <code class="code">-new_data</code> and
<code class="code">-edit_data</code> blocks which don&#39;t need to
get touched.</p><p>To make HTMLArea optional per package instance define a string
parameter <code class="code">UseWysiwygP</code> which defaults
<code class="code">0</code> for your package using the APM.</p><p>In your edit page make the following changes</p><pre class="programlisting">
        # Is WYSIWYG enabled?
        set use_wysiwyg_p [parameter::get -parameter "UseWysiwygP" -default "f"]
        
        ...
        
        {htmlarea_p $use_wysiwyg_p}
        </pre><p>The <code class="code">-on_request</code> switch should set this
value for your form.</p><pre class="programlisting">
        set htmlarea_p $use_wysiwyg_p
        </pre><p>All you need now is a configuration page where the user can
change this setting. Create a <code class="code">configure.tcl</code> file:</p><pre class="programlisting">
ad_page_contract {

    This page allows a faq admin to change the UseWysiwygP setting

} {
    {return_url ""}
}

    set title "Should we support WYSIWYG?"
    set context [list $title]

    set use_wysiwyg_p

    ad_form -name categories_mode -form {
        {enabled_p:text(radio)
            {label "Enable WYSIWYG"}
            {options {{Yes t} {No f}}}
            {value $use_wysiwyg_p}
        }
        {return_url:text(hidden) {value $return_url}}
        {submit:text(submit) {label "Change"}}
    } -on_submit {
        parameter::set_value  -parameter "UseWysiwygP" -value $enabled_p
        if {$return_url ne ""} {
            ns_returnredirect $return_url
        }
    }
</pre><p>In the corresponding ADP file write</p><pre class="programlisting">
        &lt;master&gt;
        &lt;property name="title"&gt;\@title\@&lt;/property&gt;
        &lt;property name="context"&gt;\@context\@&lt;/property&gt;

        &lt;formtemplate id="categories_mode"&gt;&lt;/formtemplate&gt;
        </pre><p>And finally reference this page from your admin page</p><pre class="programlisting">
        #TCL:
        set return_url [ad_conn url]

        #ADP:
        &lt;a href=configure?&lt;%=[export_vars -url {return_url}]%&gt;&gt;Configure&lt;/a&gt;
        </pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-schedule-procs" leftLabel="Prev" leftTitle="Scheduled Procedures"
			rightLink="tutorial-parameters" rightLabel="Next" rightTitle="Adding in parameters for your
package"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    