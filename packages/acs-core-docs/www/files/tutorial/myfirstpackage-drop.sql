-- drop script
--
-- @author joel@aufrecht.org
-- @cvs-id &Id:$
--
select content_folder__unregister_content_type(-100,'mfp_note','t');

select content_type__drop_type(
	   'mfp_note',
	   't',
	   't'
    );
