DESCRIPTION = "CGILua is a tool for creating dynamic HTML pages and manipulating input data from Web forms."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=81;endline=122;md5=9e4e9c5528e1f74cd0e5bdf953262136"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "lua5.2 lua-filesystem lua-expat"

PR = "r2"
S = "${WORKDIR}/cgilua-5.2a2"

SRC_URI = "https://github.com/keplerproject/cgilua/archive/v5.2a2.tar.gz \
           file://cgi_${PV}-make.patch \
           "

SRC_URI[md5sum] = "f9adb324c4e8331ab8033b06e8d2b7b8"
SRC_URI[sha256sum] = "24d477aa70af3eadada9feca65ed7cb2cce66681461c2dce2d6ff86361badebb"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN} = "${LUA_SHARE_DIR}/*.lua \
			   ${LUA_SHARE_DIR}/cgilua/*.lua "

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

