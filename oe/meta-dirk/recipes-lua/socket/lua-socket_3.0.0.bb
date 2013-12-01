DESCRIPTION = "LuaSocket is the most comprehensive networking support library for the Lua language."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ab6706baf6d39a6b0fa2613a3b0831e7"
HOMEPAGE = "https://github.com/diegonehab/luasocket"

RDEPENDS_${PN} += "liblua"

PR = "r0"
S = "${WORKDIR}/luasocket-3.0-rc1"

SRC_URI = "https://github.com/diegonehab/luasocket/archive/v3.0-rc1.zip \
           file://socket_${PV}-make.patch \
           "
SRC_URI[md5sum] = "86c2049ce08c9a0d43040d78da263962"
SRC_URI[sha256sum] = "a69bbc20cbb0e6c97b5e058cccd0c545d3f23c2ae05c673e62fb3aace3c23e7f"

LUA_LIB_DIR =  "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN}-dbg = "${LUA_LIB_DIR}/mime/.debug/core.so \
                   ${LUA_LIB_DIR}/socket/.debug/core.so"

FILES_${PN} = "${LUA_LIB_DIR}/mime/core.so \
               ${LUA_LIB_DIR}/socket/core.so \
               ${LUA_SHARE_DIR}/*.lua \
               ${LUA_SHARE_DIR}/socket/*.lua"

EXTRA_OEMAKE = "MYFLAGS='${CFLAGS} -DLUAV=5.2 ${LDFLAGS}'"

do_install() {
        oe_runmake install INSTALL_TOP=${D}${prefix} INSTALL_TOP_SHARE=${D}${LUA_SHARE_DIR} INSTALL_TOP_LIB=${D}${LUA_LIB_DIR}
        install -d ${D}/${docdir}/${PN}-${PV}
        install -m 0644 doc/*.html ${D}/${docdir}/${PN}-${PV}
}

