LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENCE.txt;md5=f3e5129c8991c945f57e4bf30c1746b7"
HOMEPAGE = "https://github.com/moteus/lzmq"

RDEPENDS_${PN} += "liblua zmq"

S = "${WORKDIR}/git"

SRCREV = "v0.3.1"
PV = "${SRCREV}"
SRC_URI = "git://github.com/moteus/lzmq.git \
           file://lzmq_${PV}-make.patch \
           "

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN}-dbg = "${LUA_LIB_DIR}/.debug/*.so \
					${LUA_LIB_DIR}/lzmq/.debug/*.so \
					"

FILES_${PN} = "${LUA_LIB_DIR}/*.so \
				${LUA_LIB_DIR}/lzmq/*.so \
				${LUA_SHARE_DIR}/lzmq/*.lua \
				${LUA_SHARE_DIR}/lzmq/ffi/*.lua \
				${LUA_SHARE_DIR}/lzmq/impl/*.lua \
				${LUA_SHARE_DIR}/lzmq/llthreads/*.lua \
				"

EXTRA_OEMAKE = "LUA_V=5.2"

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
        install -d ${D}/${LUA_LIB_DIR}/lzmq
}

