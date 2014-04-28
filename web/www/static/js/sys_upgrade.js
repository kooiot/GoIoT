semantic.sysupgrade = {};

// ready event
semantic.sysupgrade.ready = function() {

	// selector cache
	var
		$reboot  = $('#btn_reboot'),
	;


	$reboot
		.on('click', function() {
			window.location = "/login";
		});
	;
};


// attach ready event
	$(document)
.ready(semantic.sysupgrade.ready)
	;
