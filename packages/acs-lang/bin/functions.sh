# Functions re-used by scripts in acs-lang/bin
#
# @author Peter Marklund

# Assumes script_path to be set
get_catalog_keys() {
    file_name=$1
    echo $(${script_path}/mygrep '<msg key="([^"]+)"' $file_name)
}

find_en_us_files() {
    echo $(find ${script_path}/../../ -regex '.*/catalog/.*en_US.*\.xml' -maxdepth 3)
}
