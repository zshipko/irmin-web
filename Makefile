build:
	dune clean && dune build

test: build
	dune runtest
