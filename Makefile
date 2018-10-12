build:
	git submodule update --init || :
	dune clean && dune build

test: build
	rm -r _build
	dune runtest
