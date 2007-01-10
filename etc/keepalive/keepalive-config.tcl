# Config file for the keepalive.sh script
#
# @author Peter Marklund

# The servers_to_monitor variable should be a flat list with URLs to monitor
# on even indices and the commands to execute if the server doesn't respond
# on odd indices, like this:
# {server_url1 restart_command1 server_url2 restart_command2 ...}
set servers_to_monitor {}

# How long the keepalive script waits until it attempts another restart
set seconds_between_restarts [expr {10*60}]

# Who shall we email if the server is/cannot be restarted?
set mailto root
