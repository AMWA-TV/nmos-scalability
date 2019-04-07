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

    def start_registry( self, host_index, args ):
        "Create an NMOS registry ..."
        if host_index > -1:
            # there's a better place to do this too...
            os.system( 'mkdir -p log' )

            log_file = 'log/log%d.txt' % (host_index+1)
            clf_file = 'log/loga%d.txt' % (host_index+1)
            os.system( 'rm -f ' + log_file )
            os.system( 'rm -f ' + clf_file )

            cmd_args = 'nmos-cpp-registry'
            cmd_args += ' "{'
            cmd_args += ' \\"host_name\\": \\"' + self.mn.hosts[host_index].name + '\\",'
            if len(args):
                cmd_args += ' ' + args + ','
            cmd_args += ' \\"query_paging_limit\\": 10000,'
            cmd_args += ' \\"listen_backlog\\": 1024,'
            cmd_args += ' \\"logging_level\\": -10,'
            cmd_args += ' \\"error_log\\": \\"' + log_file + '\\",'
            cmd_args += ' \\"access_log\\": \\"' + clf_file + '\\"'
            cmd_args += ' }" &'
            self.mn.hosts[host_index].cmd( cmd_args )
            self.__wait_for_file( log_file, 600 )
            self.mdns_host = host_index

    def start_node( self, host_index, args ):
        "Create an NMOS node ..."
        if host_index > -1:
            log_file = 'log/log%d.txt' % (host_index+1)
            os.system( 'rm -f ' + log_file )
            cmd_args = 'nmos-cpp-node'
            cmd_args += ' "{'
            cmd_args += ' \\"host_name\\": \\"' + self.mn.hosts[host_index].name + '\\",'
            if len(args):
                cmd_args += ' ' + args + ','
            cmd_args += ' \\"logging_level\\": -10,'
            cmd_args += ' \\"error_log\\": \\"' + log_file + '\\"'
            cmd_args += ' }" &'
            self.mn.hosts[host_index].cmd( cmd_args )
            self.__wait_for_file( log_file, 600 )

    def __mdns_resolve( self, service ):
        "Discover and resolve a service via the nmos-cpp mDNS web service"
        host = self.mdns_host
        if host > -1:
            # 3214 is the default value for "mdns_port" in nmos-cpp-registry settings
            command = 'wget -qO - http://' + self.mn.hosts[host].IP() + ':3214/x-dns-sd/v1.0/_nmos-' + service + '._tcp/'
            self.mn.hosts[host].cmd( 'echo' )
            response = self.mn.hosts[host].cmd( command )
            try:
                data = json.loads( response )
                versions = data[0]['txt']['api_ver']
                latest = versions.split( "," )[-1]
                resolved = data[0]['txt']['api_proto'] + '://' + data[0]['addresses'][0]
                resolved += ':' + str(data[0]['port']) + '/x-nmos/' + service + '/' + latest
                return resolved
            except (LookupError, ValueError) as e:
                error( 'Error: %s\n' % e )
        else:
            error( 'No mDNS web service running!\n' )

    def find_query_api( self ):
        return self.__mdns_resolve( 'query' )

    def stop_registry( self, host_index ):
        "Stop nmos-cpp-registry on the given host (by sending an interrupt signal)"
        host_name = self.mn.hosts[host_index].name
        program = "nmos-cpp-registry"
        # this expression relies on matching the command line args used in start_registry
        cmd = 'kill -2 `ps h -C ' + program + ' | grep "' + program + ' { \\"host_name\\": \\"' + host_name + '\\"" | awk \'{print $1}\'`'
        self.mn.hosts[host_index].cmd( cmd )

    def stop_node( self, host_index ):
        "Stop nmos-cpp-node on the given host (by sending an interrupt signal)"
        host_name = self.mn.hosts[host_index].name
        program = "nmos-cpp-node"
        # this expression relies on matching the command line args used in start_node
        cmd = 'kill -2 `ps h -C ' + program + ' | grep "' + program + ' { \\"host_name\\": \\"' + host_name + '\\"" | awk \'{print $1}\'`'
        self.mn.hosts[host_index].cmd( cmd )
