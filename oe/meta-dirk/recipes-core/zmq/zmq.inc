SUMMARY = "ZeroMQ -  Distributed Computing Made Simple"
DESCRIPTION = "ZeroMQ -  Distributed Computing Made Simple"
HOMEPAGE = "http://zeromq.org"
SECTION = "libs"
LICENSE = "LGPLv3"
LIC_FILES_CHKSUM = "file://COPYING;md5=f7b40df666d41e6508d03e1c207d498f"


SRC_URI = "http://download.zeromq.org/zeromq-${PV}.tar.gz \
           file://zmq_${PV}-make.patch \
           "

S = "${WORKDIR}/zeromq-${PV}"

inherit autotools pkgconfig lib_package

# We move shared libraries for target builds to avoid
# qa warnings.
#
do_install_append_class-target() {
	if [ ${base_libdir} != ${libdir} ]
	then
		mkdir -p ${D}/${base_libdir}
		mv ${D}/${libdir}/libzmq.so.* ${D}/${base_libdir}
		tmp=`readlink ${D}/${libdir}/libzmq.so`
		ln -sf ../../${base_libdir}/$tmp ${D}/${libdir}/libzmq.so
	fi
}

BBCLASSEXTEND = "native nativesdk"
