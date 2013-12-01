DESCRIPTION = "MD5 - Cryptographic Library for Lua"
SECTION = "libs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=64;endline=111;md5=1d7b97a787be0fde7bd8c3d01b529426"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "liblua"

PR = "r1"
S = "${WORKDIR}/md5-1.2"

SRC_URI = "https://github.com/keplerproject/md5/archive/v1.2.tar.gz \
           file://md5_${PV}-make.patch "

SRC_URI[md5sum] = "c166f8a983401802a86655a8c733441e"
SRC_URI[sha256sum] = "3c016da2cf0cfeb5dfdcf3bea82b64935c4faa6eec32ae164c48d870b4583ffa"

LUA_LIB_DIR = "${libdir}/lua/5.2/md5"
LUA_SHARE_DIR = "${datadir}/lua/5.2/md5"

FILES_${PN}-dbg += "${LUA_LIB_DIR}/.debug/*.so"
FILES_${PN} = "${LUA_LIB_DIR}/*.so"

EXTRA_OEMAKE = "LUA_V=5.2"

do_configure_prepend () {
	oe_runmake clean
}

do_install () {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

