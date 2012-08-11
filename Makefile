CFLAGS=-g -O2 -Wall -Wextra -Isrc -pthread -rdynamic -DNDEBUG $(OPTFLAGS) -D_FILE_OFFSET_BITS=64
LIBS=-lzmq -ldl -lsqlite3 $(OPTLIBS)
PREFIX?=/usr/local

get_objs = $(addsuffix .o,$(basename $(wildcard $(1))))

SOURCES=$(wildcard src/**/*.c src/*.c)
OBJECTS=$(patsubst %.c,%.o,${SOURCES})
OBJECTS_NOEXT=$(filter-out ${OBJECTS_EXTERNAL},${OBJECTS})
LIB_SRC=$(filter-out src/axiur.c,${SOURCES})
LIB_OBJ=$(filter-out src/axiur.o,${OBJECTS})
TEST_SRC=$(wildcard tests/*_tests.c)
TESTS=$(patsubst %.c,%,${TEST_SRC})
MAKEOPTS=OPTFLAGS="${NOEXTCFLAGS} ${OPTFLAGS}" OPTLIBS="${OPTLIBS}" LIBS="${LIBS}" DESTDIR="${DESTDIR}" PREFIX="${PREFIX}"

all: bin/axiur tests

dev: CFLAGS=-g -Wall -Isrc -Wall -Wextra $(OPTFLAGS) -D_FILE_OFFSET_BITS=64
dev: all

${OBJECTS_NOEXT}: CFLAGS += ${NOEXTCFLAGS}


bin/axiur: build/libaxiur.a src/axiur.o
	$(CC) $(CFLAGS) src/axiur.o -o $@ $< $(LIBS)

build/libaxiur.a: CFLAGS += -fPIC
build/libaxiur.a: build ${LIB_OBJ}
	ar rcs $@ ${LIB_OBJ}
	ranlib $@

build:
	@mkdir -p build
	@mkdir -p bin

clean:
	rm -rf build bin lib ${OBJECTS} ${TESTS}
	rm -f tests/tests.log 

pristine: clean
	${MAKE} -C docs/manual clean
	cd docs/ && ${MAKE} clean

.PHONY: tests
tests: ${TESTS} 
	sh ./tests/runtests.sh

$(TESTS): %: %.c build/libaxiur.a
	$(CC) $(CFLAGS) -o $@ $< build/libm2.a $(LIBS)

check:
	@echo Files with potentially dangerous functions.
	@egrep '[^_.>a-zA-Z0-9](str(n?cpy|n?cat|xfrm|n?dup|str|pbrk|tok|_)|stpn?cpy|a?sn?printf|byte_)' $(filter-out src/bstr/bsafe.c,${SOURCES})

install: all
	install -d $(DESTDIR)/$(PREFIX)/bin/
	install bin/axiur $(DESTDIR)/$(PREFIX)/bin/
	${MAKE} ${MAKEOPTS} -C tools/m2sh install
	${MAKE} ${MAKEOPTS} -C tools/config_modules install
	${MAKE} ${MAKEOPTS} -C tools/filters install


valgrind:
	valgrind --leak-check=full --show-reachable=yes --log-file=valgrind.log --suppressions=tests/valgrind.sup ./bin/mongrel2 tests/config.sqlite localhost

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@


manual:
	dexy
	cp docs/manual/Makefile output/docs/manual/
	cp docs/manual/pastie.sty output/docs/manual/
	${MAKE} -C output/docs/manual clean book-final.pdf
	rm -rf output/docs/manual/*.dvi output/docs/manual/*.pdf
	${MAKE} -C output/docs/manual book-final.pdf
	${MAKE} -C output/docs/manual draft

release:
	git archive --format=tar --prefix=mongrel2-${VERSION}/ v${VERSION} | bzip2 -9 > mongrel2-${VERSION}.tar.bz2
	scp mongrel2-${VERSION}.tar.bz2 ${USER}@mongrel2.org:/var/www/mongrel2.org/static/downloads/
	md5sum mongrel2-${VERSION}.tar.bz2
	curl http://mongrel2.org/static/downloads/mongrel2-${VERSION}.tar.bz2 | md5sum


