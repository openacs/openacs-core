-- 2006/11/17 cognovis/nfl
--
-- Name: acs_mail_lite_complex_queue; Type: TABLE; Schema: public; Owner: cognovis; Tablespace: 
--

CREATE TABLE acs_mail_lite_complex_queue (
    id serial PRIMARY KEY,
    creation_date text,
    locking_server text,
    to_party_ids text,
    cc_party_ids text,
    bcc_party_ids text,
    to_group_ids text,
    cc_group_ids text,
    bcc_group_ids text,
    to_addr text,
    cc_addr text,
    bcc_addr text,
    from_addr text,
    subject text,
    body text,
    package_id integer,
    files text,
    file_ids text,
    folder_ids text,
    mime_type text,
    object_id integer,
    single_email_p boolean,
    no_callback_p boolean,
    extraheaders text,
    alternative_part_p boolean,
    use_sender_p boolean
);

--
-- PostgreSQL database statements - end of file
--

