fname_no_ext := qjump
fname := ${fname_no_ext}.nim

cat:
	cat Makefile

c:
	nim c ${fname}

rel:
	nim c -d:release ${fname}

small:
	nim c -d:release --opt:size --passL:-s ${fname}

install:
	nimble install

clean:
	rm -f ./${fname_no_ext}
