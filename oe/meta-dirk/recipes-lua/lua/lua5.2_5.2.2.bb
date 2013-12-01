require lua.inc

LIC_FILES_CHKSUM = "file://doc/readme.html;beginline=364;endline=401;md5=668892f07dfdc2a7766ac46f4cf8132b"

PR = "r1"

SRC_URI[md5sum] = "efbb645e897eae37cad4344ce8b0a614"
SRC_URI[sha256sum] = "3fd67de3f5ed133bf312906082fa524545c6b9e1b952e8215ffbd27113f49f00"

DEPENDS += "readline"
SRC_URI = "http://www.lua.org/ftp/lua-${PV}.tar.gz \
			file://lua5.2.pc \
			"

S = "${WORKDIR}/lua-${PV}"

inherit pkgconfig binconfig

TARGET_CC_ARCH += " -fPIC ${LDFLAGS}"
EXTRA_OEMAKE = "'CC=${CC} -fPIC' 'MYCFLAGS=${CFLAGS} -DLUA_USE_LINUX -fPIC' MYLDFLAGS='${LDFLAGS}'"

do_configure_prepend() {
    sed -i -e s:/usr/local:${prefix}:g src/luaconf.h
    sed -i -e s:/usr/local:${prefix}:g Makefile
    sed -i -e s:lib/lua/5.2/:${base_libdir}/lua/5.2/:g src/luaconf.h
}

do_compile () {
    oe_runmake linux
}

do_install () {
    oe_runmake \
        'INSTALL_TOP=${D}${prefix}' \
        'INSTALL_BIN=${D}${bindir}' \
        'INSTALL_INC=${D}${includedir}/' \
        'INSTALL_MAN=${D}${mandir}/man1' \
        'INSTALL_SHARE=${D}${datadir}/lua' \
        'INSTALL_LIB=${D}${libdir}' \
        'INSTALL_CMOD=${D}${libdir}/lua/5.2' \
        install
    install -d ${D}${libdir}/pkgconfig
    install -m 0644 ${WORKDIR}/lua5.2.pc ${D}${libdir}/pkgconfig/lua5.2.pc
    rmdir ${D}${libdir}/lua/5.2
    rmdir ${D}${libdir}/lua
    rmdir ${D}${datadir}/lua/5.2
    rmdir ${D}${datadir}/lua
}

BBCLASSEXTEND = "native"

