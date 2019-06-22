# runRestoreClear.sh
# Author:   Taylor Zowtuk
# Date:     June 21, 2019
#
# Useage:   ./runRestoreClear.sh
#
# Runs the restoreClear.s file by concatenating its contents to the GLIR.s file 
# and passing the newly created file to RARS for assembly and simulation.

rm -f test.s
cat restoreClear.s > test.s
cat ../GLIR.s >> test.s
rars sm nc me test.s
rm -f test.s