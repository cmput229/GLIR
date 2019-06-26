# runDefaultPrint.sh
# Author:   Taylor Zowtuk
# Date:     June 21, 2019
#
# Useage:   ./runDefaultPrint.sh
#
# Runs the defaultPrint.s file by concatenating its contents to the GLIR.s file 
# and passing the newly created file to RARS for assembly and simulation.

rars sm nc me defaultPrint.s