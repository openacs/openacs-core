ad_library {
    Automated tests for spell-checker

    @author Ola Hansson (ola@polyxena.net)
    @creation-date 28 September 2003
    @cvs-id $Id$
}

aa_register_case -cats { api } spellcheck__get_element_formtext {
    Test the spell-check proc that does the actual spell-checking.
} {    
    
    set base_command [list template::util::spellcheck::get_element_formtext \
			  -var_to_spellcheck var_to_spellcheck \
			  -error_num_ref error_num \
			  -formtext_to_display_ref formtext_to_display \
			  -just_the_errwords_ref just_the_errwords]
    
    #####
    #
    # Plain text without spelling mistakes
    #
    #####

    set command $base_command
    lappend command -text "This sentence does not contain any misspelled words. What we have here is plain text."
    
    aa_log "--- Correct text --- $command"

    eval $command
    
    aa_true "True statement: Text contains no misspelled words" [expr {$error_num == 0}]
    
    aa_log "Number of miss-spelled words found in text: $error_num"
    
    aa_false "False statement: Text contains misspelled word(s)" [expr {$error_num > 0}]
    
    aa_equals "Number of misspelled words found in text" $error_num 0
    
    aa_log "Returned string: $formtext_to_display"
    
    aa_true "The returned string contains a hidden var named 'var_to_spellcheck.merge_text'" \
	[regexp "var_to_spellcheck.merge_text" $formtext_to_display]

    aa_true "The returned string contains no hidden var(s) named 'var_to_spellcheck.error_N', where N is the error number." \
	![regexp "var_to_spellcheck.error_\[0-9\]*" $formtext_to_display]

    aa_true "just_the_errwords is empty" [expr {$just_the_errwords eq ""}]
    
    #####
    #
    # Plain text with spelling mistakes
    #
    #####
    
    set command $base_command
    lappend command -text "I obviosly can't spel very well ..."
    set errwords {obviosly spel}
    
    aa_log "--- Incorrect text --- $command"

    eval $command
    
    aa_true "True statement: Text contains misspelled words" [expr {$error_num > 0}]
    
    aa_log "Number of misspelled words found in text: $error_num"
    
    aa_false "False statement: Text contains no misspelled word(s)" [expr {$error_num == 0}]
    
    aa_log "Returned string: $formtext_to_display"
    
    aa_true "The returned string contains a hidden var named 'var_to_spellcheck.merge_text'" \
	[regexp "var_to_spellcheck.merge_text" $formtext_to_display]

    aa_true "The returned string contains $error_num hidden var(s) named 'var_to_spellcheck.error_N', where N is a number between 0 and [expr {$error_num - 1}]." \
	[regexp "var_to_spellcheck.error_\[0-9\]*" $formtext_to_display]

    aa_equals "The number of misspelled words matches the number of error placeholders in the merge_text" [regexp -all "var_to_spellcheck.error_\[0-9\]*" $formtext_to_display] [regexp -all "\#\[0-9\]*\#" $formtext_to_display]

    aa_true "just_the_errwords contains the errwords we expected: '[join $errwords ", "]'" [util_sets_equal_p $just_the_errwords $errwords]

    #####
    #
    # HTML without spelling mistakes
    #
    #####

    set command $base_command
    lappend command -text "This <i>sentence</i> does <b>not</b> contain <u>any</u> misspelled words. What we have here is <a href=\"\#\">HTML</a>."
    lappend command -html
    
    aa_log "--- Correctly spelled HTML fragment --- $command"

    eval $command
    
    aa_true "True statement: HTML fragment contains no misspelled words" [expr {$error_num == 0}]
    
    aa_log "Number of miss-spelled words found in HTML fragment: $error_num"
    
    aa_false "False statement: HTML fragment contains misspelled word(s)" [expr {$error_num > 0}]
    
    aa_equals "Number of misspelled words found in HTML fragment" $error_num 0
    
    aa_log "Returned string: $formtext_to_display"
    
    aa_true "The returned string contains a hidden var named 'var_to_spellcheck.merge_text'" \
	[regexp "var_to_spellcheck.merge_text" $formtext_to_display]

    aa_true "The returned string contains no hidden var(s) named 'var_to_spellcheck.error_N', where N is the error number." \
	![regexp "var_to_spellcheck.error_\[0-9\]*" $formtext_to_display]

    aa_true "just_the_errwords is empty" [expr {$just_the_errwords eq ""}]

    #####
    #
    # HTML with spelling mistakes
    #
    #####

    set command $base_command
    lappend command -text "This <i>sentence</i> <b>does</b> contain mispelled worrds. What we have here is <a href=\"\#\">HTML</a>."
    lappend command -html
    set errwords {mispelled worrds}
    
    aa_log "--- Incorrectly spelled HTML fragment --- $command"

    eval $command
    
    aa_true "True statement: HTML fragment contains misspelled words" [expr {$error_num > 0}]
    
    aa_log "Number of miss-spelled words found in HTML fragment: $error_num"
    
    aa_false "False statement: HTML fragment contains no misspelled word(s)" [expr {$error_num == 0}]
    
    aa_log "Returned string: $formtext_to_display"
    
    aa_true "The returned string contains a hidden var named 'var_to_spellcheck.merge_text'" \
	[regexp "var_to_spellcheck.merge_text" $formtext_to_display]

    aa_true "The returned string contains hidden var(s) named 'var_to_spellcheck.error_N', where N is the error number." \
	[regexp "var_to_spellcheck.error_\[0-9\]*" $formtext_to_display]

    aa_true "just_the_errwords contains the errwords we expected: '[join $errwords ", "]'" [util_sets_equal_p $just_the_errwords $errwords]

}


aa_register_case -cats { api } spellcheck__spellcheck_properties {
    Test the proc that knows if spell-checking is activated, if it should be performed,
    and which value the pull-down menu should default to.
} {    
    array set element {
	id test_element
	widget text	
	mode edit
    }

    set command {template::util::spellcheck::spellcheck_properties -element_ref element}

    # text
    aa_log "--- Spell-checking enabled on widget \"$element(widget)\"? --- $command"

    array set spellcheck [eval $command]
    aa_false "Spell-checking disabled" $spellcheck(render_p)

    if { $spellcheck(render_p) } {
	aa_log "$spellcheck(selected_option) is the default"
    }
    

    # textarea
    set element(widget) textarea
    aa_log "--- Spell-checking enabled on widget \"$element(widget)\"? --- $command"

    array set spellcheck [eval $command]
    aa_true "Spell-checking enabled" $spellcheck(render_p)
    
    if { $spellcheck(render_p) } {
	aa_log "$spellcheck(selected_option) is the default"
    }


    # richtext
    set element(widget) richtext
    aa_log "--- Spell-checking enabled on widget \"$element(widget)\"? --- $command"

    array set spellcheck [eval $command]
    aa_true "Spell-checking enabled" $spellcheck(render_p)

    if { $spellcheck(render_p) } {
	aa_log "$spellcheck(selected_option) is the default"
    }
    
}
