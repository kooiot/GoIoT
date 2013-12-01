DESCRIPTION = "WSAPI is an API that abstracts the web server from Lua web applications."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=51;endline=113;md5=9ac2e7c3defedb69616216fc9b154c0f"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "liblua lua-filesystem lua-rings lua-coxpcall libfcgi"

PR = "r1"
S = "${WORKDIR}/wsapi-1.6"

SRC_URI = "http://www.keplerproject.org/files/wsapi-1.6.tar.gz \
           file://wsapi_${PV}-make.patch \
           "

SRC_URI[md5sum] = "a4cfcd0cd2c85e3ef0214cd11e735ba4"
SRC_URI[sha256sum] = "82672c46e07e1615e0450b7605d14943b9a2be4cb3074660ce7473ea5137f14e"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN} = "${bindir}/* \
				${LUA_SHARE_DIR}/wsapi/*.lua \
				"

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

