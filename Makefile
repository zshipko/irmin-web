build:
	git submodule update --init || :
	dune clean && dune build

test: build
	dune runtest
