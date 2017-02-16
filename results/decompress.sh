for test in $(find . -mindepth 1 -maxdepth 1 -type d); do
	pushd $test
	tar -xzvf results.tar.gz
	popd
done
