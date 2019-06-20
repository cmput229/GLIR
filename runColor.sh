# runColor.sh
# Author:   Taylor Zowtuk
# Date:     June 20, 2019
#
# Useage:   ./runColor.sh
#
# Runs the colorTest.s by concatenating the colorTest.s file to the GLIR.s file.

rm -f test.s
cat colorTest.s > test.s
cat GLIR.s >> test.s
rars sm nc me test.s
rm -f test.s