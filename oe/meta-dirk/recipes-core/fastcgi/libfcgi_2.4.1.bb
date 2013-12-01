SUMMARY = "FastCGI Developer's Kit"
DESCRIPTION = "FastCGI Developer's Kit"
HOMEPAGE = "http://www.fastcgi.com"
SECTION = "libs"
LICENSE = "Open Market"
LIC_FILES_CHKSUM = "file://LICENSE.TERMS;md5=e3aacac3a647af6e7e31f181cda0a06a"


SRC_URI = "http://www.fastcgi.com/dist/fcgi.tar.gz \
           file://fcgi_2.4.1-make.patch \
           "

S = "${WORKDIR}/fcgi-2.4.1-SNAP-0311112127"

SRC_URI[md5sum] = "e79c7f4545cf1853af1e2ca3b40ab087"
SRC_URI[sha256sum] = "165604cffa37d534c348f78e4923d0f1ce4d8808b901891a9e64ebf634c4d0d5"

inherit autotools pkgconfig

# We move shared libraries for target builds to avoid
# qa warnings.
#
do_install_append_class-target() {
	if [ ${base_libdir} != ${libdir} ]
	then
		mkdir -p ${D}/${base_libdir}
		mv ${D}/${libdir}/libfcgi.so.* ${D}/${base_libdir}
		tmp=`readlink ${D}/${libdir}/libfcgi.so`
		ln -sf ../../${base_libdir}/$tmp ${D}/${libdir}/libfcgi.so
	fi
}

BBCLASSEXTEND = "native nativesdk"
