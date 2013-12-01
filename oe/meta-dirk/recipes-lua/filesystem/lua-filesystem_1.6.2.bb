DESCRIPTION = "LuaFileSystem is a Lua library with set of functions related to file systems operations."
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=63;endline=109;md5=6838cdec7c5b74b89993b8cd93b141a6"
HOMEPAGE = "https://github.com/keplerproject"

RDEPENDS_${PN} += "liblua"

PR = "r1"
S = "${WORKDIR}/luafilesystem-${PV}"

SRC_URI = "https://github.com/downloads/keplerproject/luafilesystem/luafilesystem-${PV}.tar.gz \
           file://filesystem_${PV}-make.patch \
           "

SRC_URI[md5sum] = "4e7ec93678c760c4e42cea7d28aafa13"
SRC_URI[sha256sum] = "4ad16df9958314662a459fec848d233d59313ef4992808a290053c1614532018"

LUA_LIB_DIR = "${libdir}/lua/5.2"

PACKAGES = "${PN} ${PN}-dbg"
FILES_${PN}-dbg = "${LUA_LIB_DIR}/.debug/lfs.so"
FILES_${PN} = "${LUA_LIB_DIR}/lfs.so"

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

