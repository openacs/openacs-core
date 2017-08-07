template::form create date_test 

template::element create date_test name \
  -label "Name" -datatype text -widget text

template::element create date_test date_simple \
  -label "Simple Date" -datatype date -widget date \
  -format "YYYY/MM/DD" -optional

template::element create date_test date_simple_reqd \
  -label "Simple Date (required)" -datatype date -widget date \
  -format "YYYY/MM/DD"

template::element create date_test date_long \
  -label "Long Date" -datatype date -widget date \
  -format long -optional

template::element create date_test date_text \
  -label "Textual Date" -datatype date -widget date \
  -format "YYYYt/MMt/DDt HH24t:MIt:SSt" -optional

template::element create date_test date_long_month \
  -label "Long Month" -datatype date -widget date \
  -format "YYYY/MONTH/DD" -optional

template::element create date_test date_short_month \
  -label "Short Month" -datatype date -widget date \
  -format "YYYY/MON/DD" -optional

template::element create date_test date_interval \
  -label "Custom Intervals" -datatype date -widget date \
  -format "YYYY/MM/DD HH24:MI:SS" -optional \
  -year_interval { 2000 2005 1 } \
  -month_interval { 1 5 1} \
  -day_interval { 1 31 7 } \
  -minutes_interval { 0 59 5 } \
  -seconds_interval { 0 59 15 }

template::element create date_test date_american \
  -label "American Date" -datatype date -widget date \
  -format american -optional

template::element create date_test date_ampm \
  -label "12 Hour Time" -datatype date -widget date \
  -format "HH12:MI:SS AM" -optional

template::element create date_test date_help \
  -label "Context Help" -datatype date -widget date \
  -format "YYYY/MM/DD HH12:MI:SS AM" -optional \
  -help

template::element create date_test date_exp \
  -label "Expiration date" -datatype date -widget date \
  -format expiration -optional

# Set some example variables

# Create a blank date
set today_date [template::util::date create]

# Get the tomorrow's date
set clock_value [clock scan "1 day" -base [clock seconds]]
set tomorrow_date [template::util::date set_property clock $today_date $clock_value]

# Get the SQL value
set tomorrow_sql [template::util::date::get_property sql_date $tomorrow_date]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
