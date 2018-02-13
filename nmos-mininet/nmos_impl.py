#!/usr/bin/python

import subprocess
import os
import os.path
import time
from mininet.log import info, output, error

import json

class NmosImplementation:
    "Class for creating and managing NMOS registry and nodes"

    def __init__( self, mininet ):
        self.mn = mininet
        self.mdns_host = -1

    def __wait_for_file( self, file_path, winks ):
        while not os.path.exists(file_path):
            winks -= 1
            if winks <= 0:
                break
            time.sleep(.1)

    def start_registry( self, host_index ):
        "Create an NMOS registry ..."
        if host_index > -1:
            # some system configuration that could be reasonably be made persistent
            os.system( 'sysctl kernel.pid_max=4194304 >/dev/null' )
            os.system( 'sysctl net.core.somaxconn=1024 >/dev/null' )
            os.system( 'sysctl net.core.netdev_max_backlog=5000 >/dev/null' )
            os.system( 'sysctl net.ipv4.tcp_max_syn_backlog=2048 >/dev/null' )

            # there's a better place to do this too...
            os.system( 'mkdir -p log' )

            os.system( 'rm -f log/log1.txt' )
            os.system( 'rm -f log/loga.txt' )

            cmd_args = 'nmos-cpp-registry'
            cmd_args += ' "{'
            cmd_args += ' \\"host_name\\": \\"' + self.mn.hosts[host_index].name + '\\",'
            cmd_args += ' \\"query_paging_limit\\": 10000,'
            cmd_args += ' \\"listen_backlog\\": 1024,'
            cmd_args += ' \\"logging_level\\": -10,'
            cmd_args += ' \\"error_log\\": \\"log/log1.txt\\",'
            cmd_args += ' \\"access_log\\": \\"log/loga.txt\\"'
            cmd_args += '}" &'
            self.mn.hosts[host_index].cmd( cmd_args )
            self.mdns_host = host_index

    def start_node( self, host_index ):
        "Create an NMOS node ..."
        if host_index > -1:
            log_file = 'log/log%d.txt' % (host_index+1)
            os.system( 'rm -f ' + log_file )
            cmd_args = 'nmos-cpp-node'
            cmd_args += ' "{'
            cmd_args += ' \\"host_name\\": \\"' + self.mn.hosts[host_index].name + '\\",'
            cmd_args += ' \\"logging_level\\": -10,'
            cmd_args += ' \\"error_log\\": \\"' + log_file + '\\"'
            cmd_args += '}" &'
            self.mn.hosts[host_index].cmd( cmd_args )
            self.__wait_for_file( log_file, 600 )

    def __mdns_resolve( self, service ):
        "Discover and resolve a service via the nmos-cpp mDNS web service"
        host = self.mdns_host
        if host > -1:
            command = 'wget -qO - http://' + self.mn.hosts[host].IP() + ':3214/x-mdns/_nmos-' + service + '._tcp/'
            self.mn.hosts[host].cmd( 'echo' )
            response = self.mn.hosts[host].cmd( command )
            try:
                data = json.loads( response )
                versions = data[0]['txt']['api_ver']
                latest = versions.split( "," )[-1]
                resolved = data[0]['txt']['api_proto'] + '://' + data[0]['address']
                resolved += ':' + str(data[0]['port']) + '/x-nmos/' + service + '/' + latest
                return resolved
            except ValueError, e:
                error( 'Error: %s\n' % e )
        else:
            error( 'No mDNS web service running!\n' )

    def find_query_api( self ):
        return self.__mdns_resolve( 'query' )

    def stop_registry( self, host_index ):
        "Stop nmos-cpp-registry on the given host (by sending an interrupt signal)"
        host_name = self.mn.hosts[host_index].name
        program = "nmos-cpp-registry"
        cmd = 'kill -2 `ps h -C ' + program + ' | grep "' + program + ' { \\"host_name\\": \\"' + host_name + '\\"" | awk \'{print $1}\'`'
        self.mn.hosts[host_index].cmd( cmd )

    def stop_node( self, host_index ):
        "Stop nmos-cpp-node on the given host (by sending an interrupt signal)"
        host_name = self.mn.hosts[host_index].name
        program = "nmos-cpp-node"
        cmd = 'kill -2 `ps h -C ' + program + ' | grep "' + program + ' { \\"host_name\\": \\"' + host_name + '\\"" | awk \'{print $1}\'`'
        self.mn.hosts[host_index].cmd( cmd )
