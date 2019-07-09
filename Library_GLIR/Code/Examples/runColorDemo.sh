# runColorDemo.sh
# Author:   Taylor Zowtuk
# Date:     June 20, 2019
#
# Useage:   ./runColorDemo.sh
#
# Runs the colorDemo.s file by passing to RARS for assembly and simulation.
#
# The commands used are the following:
# sm:   start execution at statement having global label 'main' if defined.
# nc:   copyright notice will not be displayed. Useful if redirecting or piping
#       program output.
# me:   display RARS messages to standard err instead of standard out. Allows
#       you to separate RARS messages from program output using redirection.

rars sm nc me colorDemo.s