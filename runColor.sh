rm -f test.s
cat colorDemo.s > test.s
cat GLIR.s >> test.s
rars test.s nc
rm -f test.s