<master>
<property name="title">#acs-subsite.Check_Your_Inbox#</property>
<property name="context">#acs-subsite.Check_Your_Inbox#</property>

#acs-subsite.lt_Please_check_your_inb#

<br />

<if @ask_question_p@ eq 1 and @require_question_p@ eq 1>

  <form method="post" action="email-password-3.tcl">
    <input type="hidden" name="first_names" value="@first_names@" />
    <input type="hidden" name="last_name" value="@last_name@" />
    <input type="hidden" name="user_id" value="@user_id@" />
    <input type="hidden" name="email" value="@email@" />

    #acs-subsite.lt_for_future_reference_#

    <br /><br />

    #acs-subsite.question# <input type="text" name="question" size="40" /><br />
    #acs-subsite.answer# <input type="text" name="answer" size="40" /><br />

    <input type="submit" value="#acs-subsite.Customize_Question#" />
  </form>

</if>
<else>

  #acs-subsite.lt_Then_come_back_to_a_h#

</else>

