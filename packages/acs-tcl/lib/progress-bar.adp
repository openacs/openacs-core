<html>
<head>
<link rel="stylesheet" type="text/css" href="/resources/acs-subsite/site-master.css" media="all">
<title@title@</title>
</head>
<body>

<div id="body">
  <div id="subsite-name">
    <if @title@ not nil>
      <h1 class="subsite-page-title">@title@</h1>
    </if>
  </div>
  <div id="navbar-body">
    <div id="subnavbar-body">


<table align="center" style="margin-top: 144px; margin-bottom: 144px;">
  <if @message_1@ not nil>
    <tr>
      <td align="center">
        <p>@message_1@</p>
      </td>
    </tr>
  </if>
  <tr>
    <td align="center">
      <div style="font-size:16pt;padding:2px; align: center;">
        <span id="progress1" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress2" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress3" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress4" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="progress5" style="background-color: #eeeeee;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      </div>
    </td>
  </tr>
  <if @message_2@ not nil>
    <tr>
      <td align="center">
        <p style="margin-top: 36px">@message_2@</p>
      </td>
    </tr>
  </if>
</table>

      <div style="clear: both;"></div>
    </div>
  </div>
</div>


<script language="javascript">
var progressEnd = 5;// set to number of progress <span>'s.
var progressColor = 'blue';// set to progress bar color
var progressInterval = 1000;// set to time between updates (milli-seconds)

var progressAt = progressEnd;
var progressTimer;
function progress_update() {
    if (progressAt > 0) {
        document.getElementById('progress'+progressAt).style.backgroundColor = '#eeeeee';
    }
    progressAt++;
    if (progressAt > progressEnd) progressAt = 1;
    document.getElementById('progress'+progressAt).style.backgroundColor = progressColor;

    // schedule progress bar to update automatically
    progressTimer = setTimeout('progress_update()',progressInterval);
}

progress_update();// start progress bar
</script>

