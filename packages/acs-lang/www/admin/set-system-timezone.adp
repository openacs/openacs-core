<master src="master">
  <property name="title">@page_title@</property>
  <property name="context">System Timzeone</property>

<p>
  Here's what the configuration looks like at this point:
</p>

<table border="1" cellpadding="8">
  <tr>
    <td>
      Timezone that OpenACS thinks it's in:
    </td>
    <td>
      <b>@system_timezone@</b>
    </td>
  </tr>

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
      Difference between local time and UTC, according to database and system setting above:
    </td>
    <td>
      <b>@system_utc_offset@ hours</b>
    </td>
  </tr>

  <tr bgcolor="yellow">
    <td>
      UTC time according to database and system setting:
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

</table>

<p>
  If the last two date and times are within a few seconds or minutes
  of each other, you're fine. Otherwise, you probably want to adjust
  what timezone OpenACS should think it's in below.
</p>

<hr>

<p>
  You can use the form below to tell ACS what timezone Oracle is
  operating in.  (There does not appear to be a nice way to ask the
  database this question automatically).
</p>

<form action="set-system-timezone" method="get">

Set Timezone:

<select name="timezone">
  <multiple name="timezones">
    <if @timezones.selected_p@ true>
      <option value="@timezones.value@" selected="selected">@timezones.label@</option>
    </if>
    <else>
      <option value="@timezones.value@">@timezones.label@</option>
    </else>
  </multiple>
</select>

<p>

<input type="submit">
</form>

