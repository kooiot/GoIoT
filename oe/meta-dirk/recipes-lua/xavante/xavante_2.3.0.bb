DESCRIPTION = "Xavante is a Lua HTTP 1.1 Web server that uses a modular architecture based on URI mapped handlers."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=61;endline=108;md5=d565935b0c81aa1d8d1c7ed81c500b4a"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "lua-filesystem lua-socket lua-copas"

PR = "r1"
S = "${WORKDIR}/xavante-2.3.0"

SRC_URI = "https://github.com/keplerproject/xavante/archive/v2.3.0.tar.gz \
           file://xavante_${PV}-config.patch \
           "

SRC_URI[md5sum] = "7a79d284a774485b8e31a6a0359480b6"
SRC_URI[sha256sum] = "1fc185f9126f12efb2ad126bd3e66a713070a9976d94f769ee9fa43681061b1b"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN} = "${LUA_SHARE_DIR}/*.lua \
			   ${LUA_SHARE_DIR}/xavante/*.lua "

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

