# Massage the requesterror array into a list data source

foreach key [array names requesterror] {
  lappend requesterrors $requesterror($key)
}
