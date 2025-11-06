<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="membership_rel::change_state.approve">
        <querytext>
            begin return membership_rel__approve(:rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.ban">
        <querytext>
            begin return membership_rel__ban(:rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.delete">
        <querytext>
            begin return membership_rel__deleted(:rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.reject">
        <querytext>
            begin return membership_rel__reject(:rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.unapprove">
        <querytext>
            begin return membership_rel__unapprove(:rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.merge">
        <querytext>
            begin return membership_rel__merge(:rel_id); end;
        </querytext>
    </fullquery>

</queryset>
