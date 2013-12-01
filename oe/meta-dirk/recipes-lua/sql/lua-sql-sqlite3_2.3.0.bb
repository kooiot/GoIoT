require lua-sql.inc

RDEPENDS_${PN} += "sqlite3"

SRC_URI += "file://sqlite3_${PV}-config.patch"

FILES_${PN}-dbg += "${LUA_LIB_DIR}/luasql/.debug/*.so"
FILES_${PN} = "${LUA_LIB_DIR}/luasql/*.so \
				${LUA_SHARE_DIR}/sql/*.lua "


