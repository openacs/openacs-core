# Procs to support testing OpenACS with Tclwebtest.
#
# For testing forums package.
#
# @author Peter Marklund

namespace eval ::twt::forums {}

ad_proc ::twt::forums::add_default_forums { server_url } {
    Adds a general forum to each class. Goes via the class admin pages.
} {
    foreach admin_url [::twt::class::get_admin_urls] {

        # Admin page of one class
        ::twt::do_request $admin_url

        # Add forum form
        link follow ~u forum-new

        form find ~n forum
        field fill "This is a general discussion forum where teachers, assistants, and students can come together to discuss the subject of the class or practical matters surrounding exams, assignments, project work etc." ~n charter
        form submit        
    }    
}

ad_proc ::twt::forums::add_postings {} {

    # Loop over all classes
    foreach class_url [::twt::class::get_urls] {

        # Class index page
        ::twt::do_request $class_url

        # Forum index page
        link follow ~u {forum-view?[^/]+$}

        # Post question
        array set question [get_question]
        link follow ~u {message-post?[^/]+$}
        field find ~n subject
        field fill $question(subject)
        field find ~n content
        field fill $question(content)
        form submit

        # Assuming here we are redirected to thread page - fragile...
        set thread_url [response url]

        # Post answer
        array set answer [get_answer]
        ::twt::user::login albert_einstein@dotlrn.test
        ::twt::do_request $thread_url
        link follow ~u {message-post?[^/]+$}
        field find ~n content
        field fill $answer(content)
        form submit
        
        ::twt::user::login_site_wide_admin
    }
}

ad_proc ::twt::forums::get_question {} {

    return {
        subject "What is the meaning of life?"
        content "Let's step back a moment...

Why do you want to know the meaning of life?

Often people ask this question when they really want the answer to some other question. Let's try and get those people back on track with some \"pre-meaning of life\" advice:

    * If you're questioning the meaning of life because you've been unhappy and depressed a good bit, click here.

    * On a related note, if you want to know the meaning of life because you feel useless and worthless, click here.

    * If you want to see our answer so that you can prove your intellectual prowess by poking holes in it, click here.

    * If something awful just happened to you or someone you care about and you don't understand why bad things happen to good people, click here.
    ...
    From http://www.aristotle.net/~diogenes/meaning1.htm

    Comments?
"
    }
}

ad_proc ::twt::forums::get_answer {} {

    return {
        content "
      I was impressed by the earnestness of your struggle to find a purpose for the life of the individual and of mankind as a whole. In my opinion there can be no reasonable answer if the question is put this way. If we speak of the purpose and goal of an action we mean simply the question: which kind of desire should we fulfill by the action or its consequences or which undesired consequences should be prevented? We can, of course, also speak in a clear way of the goal of an action from the standpoint of a community to which the individual belongs. In such cases the goal of the action has also to do at least indirectly with fulfillment of desires of the individuals which constitute a society.

      If you ask for the purpose or goal of society as a whole or of an individual taken as a whole the question loses its meaning. This is, of course, even more so if you ask the purpose or meaning of nature in general. For in those cases it seems quite arbitrary if not unreasonable to assume somebody whose desires are connected with the happenings.

      Nevertheless we all feel that it is indeed very reasonable and important to ask ourselves how we should try to conduct our lives. The answer is, in my opinion: satisfaction of the desires and needs of all, as far as this can be achieved, and achievement of harmony and beauty in the human relationships. This presupposes a good deal of conscious thought and of self-education. It is undeniable that the enlightened Greeks and the old Oriental sages had achieved a higher level in this all-important field than what is alive in our schools and universities.
"
    }
}
