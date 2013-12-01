DESCRIPTION = "LuaSQL is a simple interface from Lua to a DBMS"
SECTION = "libs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=65;endline=109;md5=7539da81347b50d1436faddb575909e0"
HOMEPAGE = "https://www.github.com/keplerproject"


PR = "r1"
S = "${WORKDIR}/luasql-${PV}"

SRC_URI = "https://github.com/keplerproject/luasql/archive/v${PV}.zip \
           file://lua-sql_${PV}-make.patch \
           "

SRC_URI[md5sum] = "b9ad1b973a69341d6b635af23f5b03f8"
SRC_URI[sha256sum] = "665a7ffa426dad32cca4e1f2e3d202783fe9865319e310d7a19a3fccb1805d83"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

RDEPENDS_${PN} += "liblua"

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

