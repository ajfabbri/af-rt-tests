VERSION_STRING = 0.57

TARGETS	= cyclictest signaltest classic_pi pi_stress \
	  hwlatdetect rt-migrate-test ptsematest sigwaittest svsematest \
	  sendme
LIBS 	= -lpthread -lrt
DESTDIR	?=
prefix  ?= /usr/local
bindir  ?= $(prefix)/bin
mandir	?= $(prefix)/share/man
srcdir	?= $(prefix)/src

CFLAGS = -Wall -Wno-nonnull -Isrc/lib
ifndef DEBUG
	CFLAGS	+= -O2
else
	CFLAGS	+= -O0 -g
endif

UTILS	= src/lib/rt-utils.o

.PHONY: all
all: $(TARGETS)

cyclictest: src/cyclictest/cyclictest.c $(UTILS)
	$(CC) $(CFLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $@ $(LIBS)

signaltest: src/signaltest/signaltest.c $(UTILS)
	$(CC) $(CFLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $@ $(LIBS)

classic_pi: src/pi_tests/classic_pi.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -D VERSION_STRING=\"$(VERSION_STRING)\" $^ -o $@ $(LIBS)

pi_stress:  src/pi_tests/pi_stress.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -D VERSION_STRING=\"$(VERSION_STRING)\" $^ -o $@ $(LIBS)

hwlatdetect:  src/hwlatdetect/hwlatdetect.py
	chmod +x src/hwlatdetect/hwlatdetect.py
	ln -s src/hwlatdetect/hwlatdetect.py hwlatdetect

rt-migrate-test: src/rt-migrate-test/rt-migrate-test.c
	$(CC) $(CFLAGS) -D_GNU_SOURCE -D VERSION_STRING=\"$(VERSION_STRING)\" $^ -o $@ $(LIBS)

ptsematest: src/ptsematest/ptsematest.c $(UTILS)
	$(CC) $(CFLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $@ $(LIBS)

sigwaittest: src/sigwaittest/sigwaittest.c $(UTILS)
	$(CC) $(CFLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $@ $(LIBS)

svsematest: src/svsematest/svsematest.c $(UTILS)
	$(CC) $(CFLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $@ $(LIBS)

sendme: src/backfire/sendme.c $(UTILS)
	$(CC) $(CFLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $@ $(LIBS)

CLEANUP  = $(TARGETS) *.o .depend *.*~ *.orig *.rej rt-tests.spec
CLEANUP += $(if $(wildcard .git), ChangeLog)

.PHONY: clean
clean:
	for F in $(CLEANUP); do find -type f -name $$F | xargs rm -f; done
	rm -f hwlatdetect

.PHONY: distclean
distclean: clean
	rm -rf BUILD RPMS SRPMS releases *.tar.gz rt-tests.spec

.PHONY: changelog
changelog:
	git log >ChangeLog

.PHONY: install
install: all
	mkdir -p "$(DESTDIR)$(bindir)" "$(DESTDIR)$(mandir)/man4"
	mkdir -p "$(DESTDIR)$(bindir)" "$(DESTDIR)$(mandir)/man8"
	cp $(TARGETS) "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(srcdir)/backfire"
	gzip src/backfire/backfire.4 -c >"$(DESTDIR)$(mandir)/man4/backfire.4.gz"
	gzip src/cyclictest/cyclictest.8 -c >"$(DESTDIR)$(mandir)/man8/cyclictest.8.gz"
	gzip src/pi_tests/pi_stress.8 -c >"$(DESTDIR)$(mandir)/man8/pi_stress.8.gz"
	gzip src/hwlatdetect/hwlatdetect.8 -c >"$(DESTDIR)$(mandir)/man8/hwlatdetect.8.gz"
	gzip src/ptsematest/ptsematest.8 -c >"$(DESTDIR)$(mandir)/man8/ptsematest.8.gz"
	gzip src/sigwaittest/sigwaittest.8 -c >"$(DESTDIR)$(mandir)/man8/sigwaittest.8.gz"
	gzip src/svsematest/svsematest.8 -c >"$(DESTDIR)$(mandir)/man8/svsematest.8.gz"
	gzip src/backfire/sendme.8 -c >"$(DESTDIR)$(mandir)/man8/sendme.8.gz"

.PHONY: release
release: clean changelog
	mkdir -p releases
	rm -rf tmp && mkdir -p tmp/rt-tests
	cp -r Makefile COPYING ChangeLog src tmp/rt-tests
	tar -C tmp -czf rt-tests-$(VERSION_STRING).tar.gz rt-tests
	rm -f ChangeLog
	cp rt-tests-$(VERSION_STRING).tar.gz releases

.PHONY: push
push:	release
	scripts/do-git-push $(VERSION_STRING)

.PHONY: pushtest
pushtest: release
	scripts/do-git-push --test $(VERSION_STRING)

rt-tests.spec: Makefile rt-tests.spec-in
	sed s/__VERSION__/$(VERSION_STRING)/ <$@-in >$@

HERE	:=	$(shell pwd)
RPMARGS	:=	--define "_topdir $(HERE)" 	\
		--define "_sourcedir $(HERE)/releases" 	\
		--define "_builddir $(HERE)/BUILD" 	\

.PHONY: rpm
rpm:	rpmdirs release rt-tests.spec
	rpmbuild -ba $(RPMARGS) rt-tests.spec

.PHONY: rpmdirs
rpmdirs:
	@[ -d BUILD ]  || mkdir BUILD
	@[ -d RPMS ]   || mkdir RPMS
	@[ -d SRPMS ]  || mkdir SRPMS

.PHONY: help
help:
	@echo ""
	@echo " rt-tests useful Makefile targets:"
	@echo ""
	@echo "    all       :  build all tests (default"
	@echo "    install   :  install tests to local filesystem"
	@echo "    release   :  build source tarfile"
	@echo "    rpm       :  build RPM package"
	@echo "    clean     :  remove object files"
	@echo "    distclean :  remove all generated files"
	@echo "    help      :  print this message"
