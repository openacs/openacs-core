<master>
  <property name="title">@page_title@</property>
  <property name="context">@context;noquote@</property>

<p>
  Here's what the configuration looks like at this point:
</p>

<table border="1" cellpadding="8">
  <tr>
    <td>
      Current time, according to the database:
    </td>
    <td>
      <b>@sysdate@</b>
    </td>
  </tr>

  <tr>
    <td>
      OpenACS Timezone setting:
    </td>
    <td>
      <b>@system_timezone@</b>
    </td>
  </tr>

  <tr>
    <td>
      Difference between database time and UTC according to OpenACS timezone setting above:
    </td>
    <td>
      <b>@system_utc_offset@ hours</b>
    </td>
  </tr>

  <tr bgcolor="yellow">
    <td>
      UTC time according to database and the OpenACS timezone setting above:
    </td>
    <td>
      <b>@sysdate_utc@</b>
    </td>
  </tr>

  <if @utc_ansi@ not nil>
    <tr bgcolor="yellow">
      <td>
        Actual UTC time according to <a
        href="http://www.timeanddate.com/worldclock/">timeanddate.com</a>:
      </td>
      <td>
        <b>@utc_ansi@</b>
      </td>
    </tr>
  </if>

  <if @correct_p@ not nil>
    <tr bgcolor=<if @correct_p@ true>"#00bb00"</if><else>"red"</else>>
      <td>
        <font color="white">
          Does it look like the OpenACS timezone setting above is correct:
        </font>
      </td>
      <td>
        <font color="white">
          <if @correct_p@ true>
            <b>YES!</b> (Congratulations)
          </if>
          <else>
            <b>NO</b>. Set below.
          </else>
        </font>
      </td>
    </tr>
  </if>



</table>

<p>
  If the last two date and times are within a few seconds or minutes
  of each other, you're fine. Otherwise, you probably want to adjust
  what timezone OpenACS should think it's in below.
</p>

<hr>

<p>
  You can use the form below to tell ACS what timezone your database is
  operating in.  (There does not appear to be a nice way to ask the
  database this question automatically).
</p>

<form action="set-system-timezone" method="post">
  <if @suggested_timezones:rowcount@ not nil and @suggested_timezones:rowcount@ gt 0>
    <p>
     <b>Your server appears to be @recommended_offset_pretty@ which includes the following timezones:</b>
    </p>
    <p>
      <select name="timezone_recommended">
        <option value="">--Select timezone--</option>
        <multiple name="suggested_timezones">
          <option value="@suggested_timezones.value@">@suggested_timezones.label@</option>
        </multiple>
      </select>
    </p>
    <p>
      <b>Or select from all zones:</b>
    </p>
  </if>
  <else>
      <p>
        <b>Set Timezone:</b>
      </p>
  </else>
  <p>
    <select name="timezone_all">
      <option value="">--Select timezone--</option>
      <multiple name="timezones">
        <option value="@timezones.value@">@timezones.label@</option>
      </multiple>
    </select> 
  </p>
  <p>
    <input type="submit" value="Set Server Timezone">  
  </p>
</form>
