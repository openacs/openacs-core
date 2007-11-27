<master>
<property name=title>#acs-subsite.Upload_Portrait#</property>
<property name="context">@context;noquote@</property>


<p>#acs-subsite.lt_How_would_you_like_the#</p>

<p>#acs-subsite.lt_Upload_your_favorite#</p>

<if @portrait_p@>
<div>
<img src="/shared/portrait-bits.tcl?user_id=@current_user_id@" alt="#acs-subsite.Your_Portrait#">
<br>
(<a href="erase?return_url=@return_url;noquote@">#acs-subsite.Erase_Portrait#</a>)
</div>
</if>

<formtemplate id="portrait_upload"></formtemplate>
