<master>
<property name="title">#acs-subsite.Email_Password#</property>


<p>#acs-subsite.lt_Please_verify_your_id#</p>

<form method="post" action="email-password-2">
  <input type="hidden" name="user_id" value="@user_id@" />

  <if @question_answer_p@ eq 0>
    #acs-subsite.Full_Name# <input type="text" name="first_names" size="20" /> <input type="text" name="last_name" size="20" />
  </if>
  <else>
    @password_question@ <input type="text" name="answer" size="20" />
  </else>


  <p><input type="submit" value="Reset and Email New Password" /></p>
</form>

