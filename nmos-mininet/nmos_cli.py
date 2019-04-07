#!/usr/bin/python

import mininet
import mininet.cli

from mininet.cli import CLI
from mininet.log import info, output, error
from nmos_impl import NmosImplementation

import subprocess
import os
import os.path
import sys
import time

import json

class NmosCLI( CLI ):
    "CLI with additional commands for NMOS scalability testing"

    def __init__( self, net, stdin=sys.stdin, script=None ):
        self.nmos_impl = NmosImplementation( net )
        mininet.cli.CLI.__init__( self, net, stdin, script )

    def __hostname_to_index( self, host_name ):
        "Convert a host name to a node index"
        if host_name in self.mn:
            index = int(host_name.partition( "h" )[2]) - 1
        else:
            index = -1
        return index

    def do_start_registry( self, host_name ):
        """Start an NMOS registry on the given host.
           Usage: start_registry <host> [<args>]"""
        args = host_name.split()
        if len(args):
            host = self.__hostname_to_index( args[0] )
            info( '*** Starting registry\n' )
            self.nmos_impl.start_registry( host, ' '.join(args[1:]) )
        else:
            error( 'No host specified!\n' )

    def do_start_node( self, range ):
        """Start an NMOS node on a host or a range of hosts.
           Usage: start_node <host>
                  start_node <first host> <last host> [<args>]"""
        args = range.split()
        if len(args):
            start = end = self.__hostname_to_index( args[0] )
            if len(args) > 1:
                end = self.__hostname_to_index( args[1] )
            info( '*** Starting %d nodes\n' % (end - start + 1) )
            try:
                for host in xrange(start, end + 1):
                    self.nmos_impl.start_node( host, ' '.join(args[2:]) )
                    info( self.mn.hosts[host].name + ' ' )
                info( '\n' )
            except IndexError, e:
                error( 'Error: %s\n' % e )
        else:
            error( 'No host specified!\n' )
    # synonym, because I keep typing the plural!
    do_start_nodes = do_start_node

    def do_mdnsd( self, range ):
        """Run an mDNS daemon for the given hosts.
           Usage: mdnsd <host>
                  mdnsd <first host> <last host>"""
        args = range.split()
        if len(args):
            start = end = self.__hostname_to_index( args[0] )
            if len(args) > 1:
                end = self.__hostname_to_index( args[1] )
            info( '*** Starting mdnsd for %d hosts\n' % (end - start + 1) )
            # start one daemon for the range
            self.mn.hosts[start].cmd( 'mdnsd' )
            # give its socket (and the pid file) a unique name
            self.mn.hosts[start].cmd( 'while [ ! -S /var/run/mdnsd -o ! -f /var/run/mdnsd.pid ] ; do sleep 1 ; done' )
            self.mn.hosts[start].cmd( 'mv /var/run/mdnsd /var/run/mdnsd%d' % (start+1) )
            self.mn.hosts[start].cmd( 'mv /var/run/mdnsd.pid /var/run/mdnsd%d.pid' % (start+1) )
            # tell libdns_sd to use that socket
            for host in xrange(start, end + 1):
                self.mn.hosts[host].cmd( 'export DNSSD_UDS_PATH=/var/run/mdnsd%d' % (start+1) )
                info( self.mn.hosts[host].name + ' ' )
            info( '\n' )
        else:
            error( 'No host specified!\n' )

    def do_nmos_get( self, line ):
        """Make a GET request and print json output.
           Usage: nmos_get http://host:port/path"""
        host = self.mn.hosts[0]
        command = 'wget -qO - ' + line
        host.cmd( 'echo > /dev/null' ) # flush stdout
        response = host.cmd( command )
        try:
            parsed = json.loads( response )
            json_output = json.dumps( parsed, indent=4, sort_keys=True )
            output( '%s\n' % json_output )
        except ValueError, e:
            error( 'Error: %s\n' % e )

    def do_query_nodes( self, host_name ):
        """Print a list of registered nodes.
           Usage: query_nodes <client host>"""
        try:
            host = self.__hostname_to_index( host_name )
            if host < 0:
                host = 0
                host_name = "h1"
            query_api = self.nmos_impl.find_query_api()
            if query_api:
                info( 'Using Query API at %s\n' % query_api )
                command = 'wget -qO - ' + query_api + '/nodes?paging.limit=10000'
                self.mn.hosts[host].cmd( 'echo > /dev/null' ) # flush stdout
                json_objects = json.loads( self.nmos_impl.mn.hosts[host].cmd( command ) )
                start_time = end_time = 0
                for node in json_objects:
                    output( 'host = %s, id = %s, version = %s\n' % (node['hostname'], node['id'], node['version']) )
                    seconds = int(node['version'].partition(":")[0])
                    if start_time == 0 or seconds < start_time:
                        start_time = seconds
                    if seconds > end_time:
                        end_time = seconds
                time_taken = end_time - start_time
                info( 'Start = %d, End = %d\n' % (start_time, end_time) )
                info( 'Time taken to register %d nodes = %d seconds.\n' % (len(json_objects),time_taken) )
            else:
                error( 'Unable to find Query API from host: %s\n' % host_name )
        except ValueError, e:
            error( 'Error: %s\n' % e )

    def do_stop_registry( self, host_name ):
        """Stop the NMOS registry on the given host.
           Usage: stop_registry <host>"""
        if len(host_name):
            host = self.__hostname_to_index( host_name )
            info( '*** Stopping registry\n' )
            self.nmos_impl.stop_registry( host )
        else:
            error( 'No host specified!\n' )

    def do_stop_node( self, range ):
        """Stop an NMOS node on the given host.
           Usage: stop_node <host>
                  stop_node <first host> <last host>"""
        args = range.split()
        if len(args):
            start = end = self.__hostname_to_index( args[0] )
            if len(args) > 1:
                end = self.__hostname_to_index( args[1] )
            info( '*** Stopping %d nodes\n' % (end - start + 1) )
            try:
                for host in xrange(start, end + 1):
                    self.nmos_impl.stop_node( host )
                    info( self.mn.hosts[host].name + ' ' )
                info( '\n' )
            except IndexError, e:
                error( 'Error: %s\n' % e )
        else:
            error( 'No host specified!\n' )
    # synonym, because I keep typing the plural!
    do_stop_nodes = do_stop_node

    def do_ovs_standalone( self, line ):
        """Configure all switches in standalone mode."""
        info( '*** Configuring switches as standalone\n' )
        for s in self.mn.switches:
            os.system( 'ovs-vsctl set bridge "' + s.name + '" fail-mode=standalone other-config:mac-table-size=4096' )
            info( s.name + ' ' )
        info( '\n' )

    def do_add_bridge( self, line ):
        """adds bridge br0 to eth0 and attaches mininet top level switch s1"""
        info( '*** adding bridge br0 to eth0 and attaching s1\n' )
        add_bridge_script = sys.path[0] + '/../bin/add_bridge.sh'
        os.system( add_bridge_script + ' br0 eth0 s1' )

    def do_delete_bridge( self, line ):
        """deleting bridge br0"""
        info( '*** deleting bridge br\n' )
        delete_bridge_script = sys.path[0] + '/../bin/delete_bridge.sh'
        os.system( delete_bridge_script + ' br0 eth0 s1' )

CLI = NmosCLI
