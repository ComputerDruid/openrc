PROG=		rc
SRCS=		checkpath.c fstabinfo.c mountinfo.c start-stop-daemon.c \
		rc-applets.c rc-depend.c rc-logger.c \
		rc-misc.c rc-plugin.c rc-service.c rc-status.c rc-update.c \
		runscript.c rc.c swclock.c

CLEANFILES=	version.h

BINDIR=		${PREFIX}/bin
SBINDIR=	${PREFIX}/sbin
LINKDIR=	${LIBEXECDIR}

BINLINKS=	rc-status
SBINLINKS=	rc-service rc-update runscript start-stop-daemon
RC_BINLINKS=	einfon einfo ewarnn ewarn eerrorn eerror ebegin eend ewend \
		eindent eoutdent esyslog eval_ecolors ewaitfile \
		veinfo vewarn vebegin veend vewend veindent veoutdent \
		service_starting service_started \
		service_stopping service_stopped \
		service_inactive service_wasinactive \
		service_hotplugged service_started_daemon service_crashed \
		checkpath fstabinfo mountinfo rc-depend \
		service_get_value service_set_value get_options save_options \
		shell_var is_newer_than is_older_than
RC_SBINLINKS=	mark_service_starting mark_service_started \
		mark_service_stopping mark_service_stopped \
		mark_service_inactive mark_service_wasinactive \
		mark_service_hotplugged mark_service_failed \
		rc-abort swclock
ALL_LINKS=	${BINLINKS} ${SBINLINKS} ${RC_BINLINKS} ${RC_SBINLINKS}
CLEANFILES+=	${ALL_LINKS}

CPPFLAGS+=	-I../includes -I../librc -I../libeinfo
LDFLAGS+=	-L../librc -L../libeinfo
LDADD+=		-lutil -lrc -leinfo

include ../../Makefile.inc
MK=		../../mk
include ${MK}/debug.mk
include ${MK}/prog.mk
include ${MK}/git.mk
include ${MK}/cc.mk

include ${MK}/${MKTERMCAP}.mk
LDADD+=		${LIBDL} ${LIBKVM}
include ${MK}/${MKPAM}.mk

${SRCS}: version.h

.PHONY:	version.h.tmp
version.h.tmp:
	echo "#define VERSION \"${VERSION}${GITVER}\"" >$@
	if test -n "${BRANDING}"; then \
		echo "#define BRANDING \"${BRANDING}\"" >> $@; \
	fi

version.h: version.h.tmp
	cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

install: all
	${INSTALL} -d ${DESTDIR}${SBINDIR}
	${INSTALL} -m ${BINMODE} ${PROG} ${DESTDIR}${SBINDIR}
	${INSTALL} -d ${DESTDIR}${BINDIR}
	for x in ${BINLINKS}; do ln -fs ${SBINDIR}/${PROG} ${DESTDIR}${BINDIR}/$$x; done
	${INSTALL} -d ${DESTDIR}${SBINDIR}
	for x in ${SBINLINKS}; do ln -fs ${PROG} ${DESTDIR}${SBINDIR}/$$x; done
	${INSTALL} -d ${DESTDIR}${LINKDIR}/bin
	for x in $(RC_BINLINKS); do ln -fs ${SBINDIR}/${PROG} ${DESTDIR}${LINKDIR}/bin/$$x; done
	${INSTALL} -d ${DESTDIR}${LINKDIR}/sbin
	for x in ${RC_SBINLINKS}; do ln -fs ${SBINDIR}/${PROG} ${DESTDIR}${LINKDIR}/sbin/$$x; done
	if test "${MKPAM}" = pam; then \
		${INSTALL} -d ${DESTDIR}${PAMDIR}; \
		${INSTALL} -m ${PAMMODE} start-stop-daemon.pam ${DESTDIR}${PAMDIR}/start-stop-daemon; \
	fi

check test::

links: rc
	for l in ${ALL_LINKS}; do ln -sf rc $$l || exit $$? ; done
