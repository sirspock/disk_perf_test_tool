
for test in $(find $1 -mindepth 1 -maxdepth 1 -type d); do
	pushd $test
	tar -czvf results.tar.gz results/
	rm -rf results/
	popd
done
