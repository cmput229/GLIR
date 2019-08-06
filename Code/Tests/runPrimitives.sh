# runPrimitves.sh
# Author:   Taylor Zowtuk
# Date:     July 28, 2019
#
# Useage:   ./runPrimitives.sh path/to/rars.jar
#
# Runs the primitives.s file by passing to RARS for assembly and simulation.
#
# The commands used are the following:
# sm:   start execution at statement having global label 'main' if defined.
# nc:   copyright notice will not be displayed. Useful if redirecting or piping
#       program output.
# me:   display RARS messages to standard err instead of standard out. Allows
#       you to separate RARS messages from program output using redirection.

java -jar $1 sm nc me primitives.s