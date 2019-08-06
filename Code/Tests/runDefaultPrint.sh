# runDefaultPrint.sh
# Author:   Taylor Zowtuk
# Date:     June 21, 2019
#
# Useage:   ./runDefaultPrint.sh path/to/rars.jar
#
# Runs the defaultPrint.s file by passing to RARS for assembly and simulation.
# Expects that rars jar is located in the Tests/ directory.
#
# The commands used are the following:
# sm:   start execution at statement having global label 'main' if defined.
# nc:   copyright notice will not be displayed. Useful if redirecting or piping
#       program output.
# me:   display RARS messages to standard err instead of standard out. Allows
#       you to separate RARS messages from program output using redirection.

java -jar $1 sm nc me defaultPrint.s