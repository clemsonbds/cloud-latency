#!/bin/bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)

benchmarks_dir=${REPO}/benchmarks
install_dir=$HOME

# fetch and compile benchmark suites from the install/build scripts
for bench_dir in `find ${benchmarks_dir} -maxdepth 1 -mindepth 1 -type d`; do
	dest_dir=${install_dir}/`basename ${bench_dir}`
	${bench_dir}install.sh ${dest_dir}
	${bench_dir}build.sh ${dest_dir}
done
