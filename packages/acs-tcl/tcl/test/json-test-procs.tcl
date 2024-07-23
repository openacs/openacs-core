ad_library {

    Test procs in defined in tcl/json-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        util::json2dict
        util::tdomNodes2dict
    } \
    json_to_dict {

        Test JSON to dict conversions

    } {
        set json {{"results":[{"name":"bootstrap-icons","latest":"https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/bootstrap-icons.svg","filename":"bootstrap-icons.svg","description":"Official open source SVG icon library for Bootstrap","version":"1.11.3"}],"total":1,"available":3}}
        set jsonDict [util::json2dict $json]
        aa_equals cdnjs-API $jsonDict {results {{name bootstrap-icons latest https://cdnjs.cloudflare.com/ajax/libs/bootstrap-icons/1.11.3/bootstrap-icons.svg filename bootstrap-icons.svg description {Official open source SVG icon library for Bootstrap} version 1.11.3}} total 1 available 3}

        set json {{
            "Verlag": "De Gruyter",
            "Auflage": {"nr": 1, "jahr": 2020 },
            "Autor": [
                      {"Vorname": "Hans Robert", "Familienname": "Hansen"},
                      {"Vorname": "Jan ", "Familienname": "Mendling"},
                      {"Vorname": "Gustaf", "Familienname": "Neumann"} ],
            "Schlagworte": ["Wirtschaftsinformatik", "Einführung"]
        }}
        set jsonDict [util::json2dict $json]
        aa_equals cdnjs-API $jsonDict {Verlag {De Gruyter} Auflage {nr 1 jahr 2020} Autor {{Vorname {Hans Robert} Familienname Hansen} {Vorname {Jan } Familienname Mendling} {Vorname Gustaf Familienname Neumann}} Schlagworte {Wirtschaftsinformatik Einführung}}

    }
