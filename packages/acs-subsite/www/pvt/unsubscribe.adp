<master>
<property name="title">Confirm Unsubscribe</property>


<p>Confirm that you'd like to unsubscribe from @site_link@.</p>

<if @on_vacation_p@ eq "t">

You are current marked as being on vacation until @pretty_no_alerts_until_date@.  If you'd like to start receiving email alerts again, just <a href="set-on-vacation-to-null">tell us that you're back</a>.

<ul>

</if>
<else>

If you are interested in this community but wish to stop receiving
email then you might want to 

<ul>
<li>tell the system that you're going on vacation until 
<form method="get" action="set-on-vacation-until">
@date_entry_widget@
<input type="submit" value="Put email on hold" />
</form>
<p>

</else>

<if @parameter_enabled_p@ eq 1>
  <if @dont_spam_me_p@ eq "f">
    <li>The system is currently set to send you email notifications. Click here to  <a href="toggle-dont-spam-me-p">tell the system not to send you any email notifications</a>.</li>
  </if>
  <else>
    <li>The system is currently set to <em>not</em> send you any email notifications. Click here <a href="toggle-dont-spam-me-p">allow system to send you email notifications</a>.</li>
  </else>
</if>

</ul>

<p>

However, if you've totally lost interest in this community or topic,
then you can <a href="unsubscribe-2">ask the server to mark your
account as deleted</a>.

