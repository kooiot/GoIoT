DESCRIPTION = "lua-expat"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=61;endline=105;md5=233d45b83cb017f713f5293cabd9f391"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "liblua expat"

PR = "r1"
S = "${WORKDIR}/lua-expat-1f41c74ce686"

SRC_URI = "http://code.matthewwild.co.uk/lua-expat/archive/1f41c74ce686.tar.gz \
           file://expat_${PV}-make.patch \
           "

SRC_URI[md5sum] = "9da3eb618aaf1547a1a75504c8185cee"
SRC_URI[sha256sum] = "efe74a0ff7375ee5fe459aefff723c0efd5ebba7d05de34f7ebc334147c0731b"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN}-dbg += "${LUA_LIB_DIR}/.debug/*.so"
FILES_${PN} = "${LUA_LIB_DIR}/*.so \
				${LUA_SHARE_DIR}/lxp/*.lua "

EXTRA_OEMAKE = "LUA_V=5.2"

do_install() {
		oe_runmake install DESTDIR=${D}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

