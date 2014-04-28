semantic.item = {};

// ready event
semantic.item.ready = function() {

	// selector cache
	var
		$items = $('.ui.items .item'),
		$stars = $('.ui.items .item .ui.label'),
		$buttons = $('.ui.items .item .ui.button'),
		$item  = $('.ui.items .item').not($stars).not($buttons),
		// alias
		handler = {
			onclick: function() {
				var id = $(this).attr("lname");
				window.location = "/apps/"+id;
			}

		}
	;

	$stars
		.on('click', function(event) {alert('stars'); event.stopPropagation();});
	;

	$buttons
		.on('click', function(event) {event.stopPropagation();});
	;

	$item
		.on('click', handler.onclick)
		;

};


// attach ready event
	$(document)
.ready(semantic.item.ready)
	;
