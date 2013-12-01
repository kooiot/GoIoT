DESCRIPTION = "lua-zqm"
LICENSE = "OpenDomain"
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=2a42bad4cc9c1f188181fded2c969311"
HOMEPAGE = "https://github.com/Neopallium/lua-zmq"

RDEPENDS_${PN} += "liblua zmq"

S = "${WORKDIR}/git"

SRCREV = "master"
PV = "1.0+git${SRCREV}"
SRC_URI = "git://github.com/Neopallium/lua-zmq.git \
           file://zmq_git-make.patch \
           "

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN}-dbg += "${LUA_LIB_DIR}/.debug/*.so"
FILES_${PN} = "${LUA_LIB_DIR}/*.so \
				${LUA_SHARE_DIR}/zmq/*.lua "

inherit cmake pkgconfig

EXTRA_OEMAKE = "LUA_V=5.2"

