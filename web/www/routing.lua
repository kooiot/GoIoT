-----------------------------------------------
-----------------------------------------------

map('^/app/view/(.*)', 'app/detail')
map('^/store/view/(.*)', 'store/detail')
map('^/store/get/(.*)', 'store/install')
map('^/store/upgrade/(.*)', 'store/upgrade')
map('^/store/author/(.*)', 'store/author')
map('^/apps/([^/]+)/?(.*)$', 'app/route')
