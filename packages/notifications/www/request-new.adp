<master>
<property name="&doc">doc</property>
<property name="context">@context;literal@</property>

<h1>@page_title@</h1>
<formtemplate id="subscribe"></formtemplate>
<if @sse_notifications_p;literal@ true>
  <script <if @::__csp_nonce@ not nil> nonce="@::__csp_nonce;literal@"</if>>
    document.querySelector('form[name=subscribe]').addEventListener('submit', function (evt) {
      if (this.elements.namedItem('delivery_method_id').value === '@sse_delivery_method_id@') {
        evt.preventDefault();
        // We need to ask the user for permission to display notifications.
        Notification.requestPermission().then((permission) => {
            // If the user accepts, we let the submission proceed.
            if (permission === 'granted') {
                this.submit();
            }
        });
      }
    });
  </script>
</if>
