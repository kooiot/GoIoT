DESCRIPTION = "Rings is a library which provides a way to create new Lua states from within Lua."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=63;endline=105;md5=2e20c79809b0e620628ac7d65eb7760b"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "lua5.2"

PR = "r1"
S = "${WORKDIR}/rings-v_1_3_0"

SRC_URI = "https://github.com/keplerproject/rings/archive/v_1_3_0.zip \
           file://rings_${PV}-make.patch \
           file://rings_${PV}-ldflags.patch \
           "

SRC_URI[md5sum] = "afc8fd2ed3fa62d3e11828f2c8a9184f"
SRC_URI[sha256sum] = "06040f0a00af744d1efe9aacabd581e1e28a44cfcac1021d5d5a4b22f2cac931"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN}-dbg += "${LUA_LIB_DIR}/.debug/*.so"
FILES_${PN} = "${LUA_LIB_DIR}/*.so \
				${LUA_SHARE_DIR}/*.lua "

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

