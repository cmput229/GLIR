rm -f test.s
cat colorTest.s > test.s
cat GLIR.s >> test.s
rars test.s nc
rm -f test.s