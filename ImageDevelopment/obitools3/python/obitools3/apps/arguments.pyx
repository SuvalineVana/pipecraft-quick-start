#cython: language_level=3

'''
Created on 27 mars 2016

@author: coissac
'''

import argparse
import sys


from .command import getCommandsList

class ObiParser(argparse.ArgumentParser): 
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

cpdef buildArgumentParser(str configname, 
                          str softname):
    parser = ObiParser()
    
    parser.add_argument('--version',   dest='%s:version' % configname, 
                                       action='store_true', 
                                       default=False, 
                        help='Print the version of %s' % softname)

    parser.add_argument('--log',       dest='%s:log' % configname, 
                                       action='store',
                                       type=str,
                                       default=None, 
                        help='Create a logfile')


    subparsers = parser.add_subparsers(title='subcommands',
                                       description='valid subcommands',
                                       help='additional help')
    
    commands = getCommandsList()
    
    for c in commands:
        module = commands[c]
        
        if hasattr(module, "run"):
            if hasattr(module, "__title__"):
                sub = subparsers.add_parser(c,help=module.__title__)
            else:
                sub = subparsers.add_parser(c)
    
            if hasattr(module, "addOptions"):
                module.addOptions(sub)
            
            sub.set_defaults(**{'%s:module'  % configname : module})
            sub.set_defaults(**{'%s:modulename'  % configname : c})
              
    return parser
