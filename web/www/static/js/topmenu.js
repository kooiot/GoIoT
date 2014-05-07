semantic.button = {};

// ready event
semantic.button.ready = function() {

	// selector cache
	var
		$buttons = $('.ui.buttons .button'),
		$login  = $('#btn_login'),
		$button  = $('.ui.button').not($buttons).not($login),
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

	$login
		.on('click', function() {
			window.location = "/user/login";
		});
	;
};


// attach ready event
	$(document)
.ready(semantic.button.ready)
	;
