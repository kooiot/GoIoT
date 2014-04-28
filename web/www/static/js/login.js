semantic.button = {};

// ready event
semantic.button.ready = function() {

	// selector cache
	var
		$buttons = $('.ui.buttons .button'),
		$signup  = $('#btn_signup'),
		$logout  = $('#btn_logout'),
		$button  = $('.ui.button').not($buttons).not($signup).not($logout),
		// alias
		handler = {

			activate: function() {
				$(this)
					.addClass('active')
					.siblings()
					.removeClass('active')
					;
			}

		}
	;

	$buttons
		.on('click', handler.activate)
		;

	$signup
		.on('click', function() {
			window.location = "/register";
		});
	;

	$logout
		.on('click', function() {
			window.location = "/logout";
		});
	;
};


// attach ready event
	$(document)
.ready(semantic.button.ready)
	;
