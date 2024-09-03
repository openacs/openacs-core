#
#    Copyright (C) 2024 Gustaf Neumann, neumann@wu-wien.ac.at
#
#       Vienna University of Economics and Business
#       Institute of Information Systems and New Media
#       A-1020, Welthandelsplatz 1
#       Vienna, Austria
#
#    This is a BSD-Style license applicable for this file.
#
#    Permission to use, copy, modify, distribute, and sell this
#    software and its documentation for any purpose is hereby granted
#    without fee, provided that the above copyright notice appears in
#    all copies and that both that copyright notice and this permission
#    notice appear in supporting documentation. We make no
#    representations about the suitability of this software for any
#    purpose.  It is provided "as is" without express or implied
#    warranty.
#

namespace eval ::acs {

    ##########################################################################
    #
    # Generic Container class
    #
    ##########################################################################
    nx::Class create ::acs::Container {
        #
        # This class captures the information whether or not OpenACS
        # is running inside a container. This is important since the
        # container provide container-internal and external IP
        # addresses. The internal IP addresses are e.g. needed when
        # running a regression test inside a container, while the
        # external address is needed for e.g. redirects.
        #
        # In the case of Docker, the networking information can be
        # collected in a container setup script with the following
        # command.
        #
        #     curl -s --unix-socket /var/run/docker.sock \
        #             -o /scripts/docker.config \
        #             http://localhost/containers/${HOSTNAME}/json
        #
        # The docker API/pipe requires ROOT permissions for accessing
        # the socket (or the full docker setup with the "docker"
        # user). To keep the docker container small, we follow the
        # approach with the root privilege, but this has to be done in
        # a setup script before NaviServer switches to the
        # non-privileged user. A sample setup script will be made
        # available together with the openacs docker container.
        #
        # In general, one can extend this class to handle as well
        # other container mechanisms via subclassing and determining
        # the kind of container during startup. So far, there is only
        # Docker support.
        #
        # Create the container object e.g. as
        #
        #      ::acs::Container create acs::container
        #

        :public method active_p {} {
            #
            # Check, if we are running inside a Docker container
            #
            return [info exists :containerMapping]
        }

        :public method mapping {} {
            #
            # Return the container mapping
            #
            expr {[:active_p] ? ${:containerMapping} : ""}
        }

        :method init {} {
            #
            # In case, a docker mapping is provided, source it to make it
            # accessible during configuration. The mapping file is a Tcl script
            # providing at least the Tcl dict ::docker::containerMapping
            # containing the docker mapping. A dict key like "8080/tcp" (internal
            # port) will return a dict containing the keys "host", "port" and
            # "proto" (e.g. proto https host 192.168.1.192 port 58115).
            #
            if {[file exists /scripts/docker-dict.tcl]} {
                source /scripts/docker-dict.tcl
                if {[info exists ::docker::containerMapping]} {
                    set :containerMapping $::docker::containerMapping
                }
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
