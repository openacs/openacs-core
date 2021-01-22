
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Sending HTML email from your application}</property>
<property name="doc(title)">Sending HTML email from your application</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-css-layout" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-caching" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-html-email" id="tutorial-html-email"></a>Sending HTML email from your
application</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:jade\@rubick.com" target="_top">Jade Rubick</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>Sending email is fairly simple using the acs-mail-lite package.
Sending HTML email is only slightly more complicated.</p><pre class="programlisting">
    set subject "my subject"

    set message "&lt;b&gt;Bold&lt;/b&gt; not bold"

    set from_addr "me\@myemail.com"

    set to_addr "me\@myemail.com"

    # the from to html closes any open tags.
    set message_html [ad_html_text_convert -from html -to html $message]

    # some mailers chop off the last few characters.
    append message_html "   "
    set message_text [ad_html_text_convert -from html -to text $message]
        
    set message_data [build_mime_message $message_text $message_html]
    
    set extra_headers [ns_set new]

    ns_set put $extra_headers MIME-Version [ns_set get $message_data MIME-Version]
    ns_set put $extra_headers Content-ID [ns_set get $message_data Content-ID]
    ns_set put $extra_headers Content-Type [ns_set get $message_data Content-Type]
    set message [ns_set get $message_data body]
    
    acs_mail_lite::send \
        -to_addr $to_addr \
        -from_addr $from_addr \
        -subject $subject \
        -body $message \
        -extraheaders $extra_headers
    
</pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-css-layout" leftLabel="Prev" leftTitle="Laying out a page with CSS instead of
tables"
		    rightLink="tutorial-caching" rightLabel="Next" rightTitle="Basic Caching"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		