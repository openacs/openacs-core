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
        // Check whether notification permissions have already been granted;
        // if so, create a notification
        const notification = messageToNotification(message);
    } else if (Notification.permission !== 'denied') {
        // We need to ask the user for permission
        Notification.requestPermission().then((permission) => {
            // If the user accepts, let's create a notification
            if (permission === 'granted') {
                const notification = messageToNotification(message);
            }
        });
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
