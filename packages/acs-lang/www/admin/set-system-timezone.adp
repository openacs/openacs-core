<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<p>
  Here's what the configuration looks like at this point:
</p>

<table border="1" cellpadding="8">
  <tr>
    <td>
      Current time, according to the database:
    </td>
    <td>
      <strong>@sysdate@</strong>
    </td>
  </tr>

  <tr>
    <td>
      OpenACS Timezone setting:
    </td>
    <td>
      <strong>@system_timezone@</strong>
    </td>
  </tr>

  <tr>
    <td>
      Difference between database time and UTC according to OpenACS timezone setting above:
    </td>
    <td>
      <strong>@system_utc_offset@ hours</strong>
    </td>
  </tr>

  <tr style="background: yellow">
    <td>
      UTC time returned from time server  <a
        href="http://www.timeanddate.com/worldclock/">timeanddate.com</a>:
    </td>
    <td>
      <strong>@utc_from_page@</strong>
    </td>
  </tr>

  <tr style="background: yellow">
    <td>
      UTC time according to database and the OpenACS timezone setting above:
    </td>
    <td>
      <strong>@sysdate_utc@</strong>
    </td>
  </tr>

  <if @utc_ansi@ not nil>
    <tr style="background: yellow">
      <td>
        Actual UTC time according to <a
        href="http://www.timeanddate.com/worldclock/">timeanddate.com</a>:
      </td>
      <td>
        <strong>@utc_ansi@</strong>
      </td>
    </tr>
  </if>

  <if @correct_p@ not nil>
    <tr style=<if @correct_p;literal@ true>"background: #00bb00"</if><else>"background: red"</else>>
      <td>
        <span style="color: white">
          Does it look like the OpenACS timezone setting above is correct:
        </span>
      </td>
      <td>
        <span style="color: white">
          <if @correct_p;literal@ true>
            <strong>YES!</strong> (Congratulations)
          </if>
          <else>
            <strong>NO</strong>. Set below.
          </else>
        </span>
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
     <strong>Your server appears to be @recommended_offset_pretty@ which includes the following timezones:</strong>
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
      <strong>Or select from all zones:</strong>
    </p>
  </if>
  <else>
      <p>
        <strong>Set Timezone:</strong>
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
