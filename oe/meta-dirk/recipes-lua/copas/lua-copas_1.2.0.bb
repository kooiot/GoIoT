DESCRIPTION = "Copas is a dispatcher based on coroutines that can be used by TCP/IP servers."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=60;endline=109;md5=590cda4282e9a8adca435648c46104ca"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "liblua lua-socket lua-coxpcall"

PR = "r0"
S = "${WORKDIR}/copas-1_2_0"

SRC_URI = "https://github.com/keplerproject/copas/archive/v1_2_0.tar.gz \
           file://copas_${PV}-make.patch \
           "

SRC_URI[md5sum] = "674f44c6703c03142e1320b59e205f56"
SRC_URI[sha256sum] = "800ddceccfb90942e8dbfa7e6530f4cf880cb623ea04314eeeb332c7596613c5"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN} = "${LUA_SHARE_DIR}/*.lua"

do_compile() {
}

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

