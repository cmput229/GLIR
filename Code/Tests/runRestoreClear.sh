# runRestoreClear.sh
# Author:   Taylor Zowtuk
# Date:     June 21, 2019
#
# Useage:   ./runRestoreClear.sh
#
# Runs the restoreClear.s file by concatenating its contents to the GLIR.s file 
# and passing the newly created file to RARS for assembly and simulation.

rars sm nc me restoreClear.s