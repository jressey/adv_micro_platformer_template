#!/usr/bin/env python

# Parses a file and types it to screen, if it encounters the word "include"
# followed by a filename at the beginning of a line that entire file printed
# instead of the include-line.

import sys
import os.path
import optparse

parser = optparse.OptionParser(
    usage = "Usage: %prog [options] filename",
    description = "Parse a source file and include other files.",
    option_list = [
        optparse.make_option("-o", "--optimize", dest = "optimize", action = "store_true", default = False, help = "Removes comments and indentation")
    ])

options, args = parser.parse_args()
if 1 != len(args):
    parser.error("Only one filename is supported.")
    print "options: " + str(options)
    print "args: " + str(args)

if not os.path.exists(args[0]):
    sys.exit("Error: Filename " + args[0] + " not found.")
                            
sourceFile = file(args[0])
for line in sourceFile:
    lineStripped = line.strip()
    if lineStripped.startswith("include"):
        lineInclude = lineStripped.split()
        if not os.path.exists(lineInclude[1]):
                    sys.exit("Included file " + lineInclude[1] + " not found.")
        includeFile = file(lineInclude[1])
        if not os.path.exists(lineInclude[1]):
            sys.exit("Included file " + lineInclude[1] + " not found.")
        for incLine in includeFile:
            incStripped = incLine.strip()
            if incStripped.startswith("--") and options.optimize:
                pass
            else:
                if options.optimize:
                    if not incStripped=="":
                        print incStripped
                else:
                    print incLine,
    elif lineStripped.startswith("--") and options.optimize:
        pass
    else:
        if options.optimize:
            if not lineStripped=="":
                print lineStripped
        else:
            print line,
