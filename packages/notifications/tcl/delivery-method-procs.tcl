ad_library {

    Notification Delivery Methods

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::delivery {

    ad_proc -public deliver {
        {-delivery_method_id:required}
        {-to:required}
        {-content:required}
    } {
        do the delivery of certain content to a particular user
    } {
        # FIXME: implement
    }

}
