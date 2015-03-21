semantic.dropdown = {};

// ready event
semantic.dropdown.ready = function() {
	$('.ui.dropdown')
		.dropdown()
		;
};


// attach ready event
$(document)
  .ready(semantic.dropdown.ready)
;
