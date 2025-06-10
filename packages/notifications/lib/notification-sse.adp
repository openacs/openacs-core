<%
  #
  # Subscribe to the notification event
  #
%>
<script <if @::__csp_nonce@ not nil> nonce="@::__csp_nonce;literal@"</if>>

function messageToNotification(message) {
    const notification = new Notification(
        message.subject,
        {
            body: message.content,
            icon: `/shared/portrait-bits.tcl?user_id=${message.from_user.user_id}`
        }
    );
    return notification;
}

function notifyMe(message) {
    if (!('Notification' in window)) {
        console.warn('This browser does not support desktop notification');
        return
    }

    if (Notification.permission === 'granted') {
        // Check whether notification permissions have already been
        // granted; if so, create a notification. Note that we cannot
        // request consent here if it was not granted earlier, because
        // the request should follow a user interaction.
        const notification = messageToNotification(message);
    } else {
        console.warn('Your browser does not have permission to display this notification.');
        return
    }
}

const evtSource = new EventSource('/notifications/sse/subscribe');
evtSource.onmessage = (event) => {
    const message = JSON.parse(event.data);
    notifyMe(message);
    console.log(message);
};

</script>
