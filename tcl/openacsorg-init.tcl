# openeconomies-init.tcl

ad_library {
    Defines custom ETP applications used on OpenACS.org

    @cvs-id $Id$
    @author Luke Pond dlpond@pobox.com
    @date 18 September 2001
}


etp::modify_application default {
    index_template        templates/default-index
    content_template      templates/default-content
}    

etp::define_application toplevel {
    index_template        templates/homepage-index
}

etp::define_application site-node {
    index_template        templates/site-node
}

# new design (olah)
etp::define_application homepage-new {
    index_template        templates/homepage-new-index
}

etp::define_application community {
    index_template        templates/community-index
    content_content_attr_name "Special Events HTML"
}

# new design (olah)
etp::define_application community-new {
    index_template        templates/community-new-index
    content_content_attr_name "Spec Events HTML"
}

etp::modify_application news {
    index_template        templates/news-index
    content_template      templates/news-content
}    

etp::modify_application faq {
    index_template        templates/faq-index
    content_template      templates/faq-content
}    
