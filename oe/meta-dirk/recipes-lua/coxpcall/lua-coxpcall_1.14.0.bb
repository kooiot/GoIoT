DESCRIPTION = "Coxpcall encapsulates the protected calls with a coroutine based loop, so errors can be dealed without the usual pcall/xpcall issues with coroutines"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/us/license.html;beginline=53;endline=09;md5=d41d8cd98f00b204e9800998ecf8427e"
HOMEPAGE = "https://www.github.com/keplerproject"

RDEPENDS_${PN} += "lua5.2"

PR = "r2"
S = "${WORKDIR}/coxpcall-1_14_0"

SRC_URI = "https://github.com/keplerproject/coxpcall/archive/v1_14_0.zip \
           file://coxpcall_${PV}-make.patch \
           "
SRC_URI[md5sum] = "6981434604030888805570e5498d0fad"
SRC_URI[sha256sum] = "ea9cdb226c0b1f93d15cf40e1db1ffa9ac9c7bbb73e7e9dedb54895fdeaf3618"

LUA_LIB_DIR = "${libdir}/lua/5.2"
LUA_SHARE_DIR = "${datadir}/lua/5.2"

FILES_${PN} = "${LUA_SHARE_DIR}/*.lua"

do_configure() {
}

do_install() {
		oe_runmake install PREFIX=${D}/${prefix}
		install -d ${D}/${docdir}/${PN}-${PV}
		install -m 0644 doc/us/* ${D}/${docdir}/${PN}-${PV}
}

