<html>
<head>
<link rel="stylesheet" type="text/css" href="/resources/acs-subsite/site-master.css" media="all">
<title>@title@</title>
</head>
<body>

<div id="page-body">
  <if @title@ not nil>
    <h1 class="page-title">@title;noquote@</h1>
  </if>

  <div class="boxed-user-message">
    <if @message_1@ not nil>
      <h3>@message_1@</h3>
    </if>

    <div class="body">
      <span id="progress1" style="background-color: white;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      <span id="progress2" style="background-color: white;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      <span id="progress3" style="background-color: white;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      <span id="progress4" style="background-color: white;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
      <span id="progress5" style="background-color: white;">&nbsp;&nbsp;&nbsp;&nbsp;</span>
    </div>

    <if @message_2@ not nil>
      <p>@message_2@</p>
    </if>
  </table>

  <div style="clear: both;"></div>
  </div>
</div>


<script type="text/javascript" <if @::__csp_nonce@ not nil> nonce="@::__csp_nonce;literal@"</if>>
var progressEnd = 5;// set to number of progress span's.
var progressColor = 'blue';// set to progress bar color
var progressInterval = 1000;// set to time between updates (milli-seconds)

var progressAt = progressEnd;
var progressTimer;
function progress_update() {
    if (progressAt > 0) {
        document.getElementById('progress'+progressAt).style.backgroundColor = 'white';
    }
    progressAt++;
    if (progressAt > progressEnd) progressAt = 1;
    document.getElementById('progress'+progressAt).style.backgroundColor = progressColor;

    // schedule progress bar to update automatically
    progressTimer = setTimeout('progress_update()',progressInterval);
}

progress_update();// start progress bar
</script>

