// namespace
window.semantic = {
  handler: {}
};

// Allow for console.log to not break IE
if (typeof window.console == "undefined" || typeof window.console.log == "undefined") {
  window.console = {
    log  : function() {},
    info : function(){},
    warn : function(){}
  };
}
if(typeof window.console.group == 'undefined' || typeof window.console.groupEnd == 'undefined' || typeof window.console.groupCollapsed == 'undefined') {
  window.console.group = function(){};
  window.console.groupEnd = function(){};
  window.console.groupCollapsed = function(){};
}
if(typeof window.console.markTimeline == 'undefined') {
  window.console.markTimeline = function(){};
}
window.console.clear = function(){};

// ready event
semantic.ready = function() {

  // selector cache
  var

    $peek             = $('.peek'),
    $peekItem         = $peek.children('.menu').children('a.item'),
    $peekSubItem      = $peek.find('.item .menu .item'),
    $sortableTables   = $('.sortable.table'),

    $ui               = $('.ui').not('.hover, .down'),
    $swap             = $('.theme.menu .item'),
    $menu             = $('#menu'),
    $hideMenu         = $('#menu .hide.item'),
    $sortTable        = $('.sortable.table'),
    $demo             = $('.demo'),
    $waypoints        = $peek.closest('.tab, .container').find('h2').first().siblings('h2').addBack(),

    $menuPopup        = $('.ui.main.menu .popup.item'),
    $menuDropdown     = $('.ui.main.menu .dropdown'),
    $pageTabMenu      = $('body > .tab.segment .tabular.menu'),
    $pageTabs         = $('body > .tab.segment .menu .item'),

    $downloadDropdown = $('.download.buttons .dropdown'),

    $helpPopup        = $('.header .help.icon'),

    $example          = $('.example'),
    $shownExample     = $example.filter('.shown'),

    $developer        = $('.developer.item'),
    $overview         = $('.overview.item, .overview.button'),
    $designer         = $('.designer.item'),

    $sidebarButton    = $('.attached.launch.button'),

    $increaseFont     = $('.font .increase'),
    $decreaseFont     = $('.font .decrease'),

    $code             = $('div.code').not('.existing'),
    $existingCode     = $('.existing.code'),

    // alias
    handler
  ;


  // event handlers
  handler = {

    createIcon: function() {
      $example
        .each(function(){
          $('<i/>')
            .addClass('icon code')
            .prependTo( $(this) )
          ;
        })
      ;
    },

    getSpecification: function(callback) {
      var
        url = $(this).data('url') || false
      ;
      callback = callback || function(){};
      if(url) {
        $.ajax({
          method: 'get',
          url: url,
          type: 'json',
          complete: callback
        });
      }
    },

    font: {

      increase: function() {
        var
          $container = $(this).parent().prev('.ui.segment'),
          fontSize   = parseInt( $container.css('font-size'), 10)
        ;
        $container
          .css('font-size', fontSize + 1)
        ;
      },
      decrease: function() {
        var
          $container = $(this).parent().prev('.ui.segment'),
          fontSize   = parseInt( $container.css('font-size'), 10)
        ;
        $container
          .css('font-size', fontSize - 1)
        ;
      }
    },
    getIndent: function(text) {
      var
        lines           = text.split("\n"),
        firstLine       = (lines[0] === '')
          ? lines[1]
          : lines[0],
        spacesPerIndent = 2,
        leadingSpaces   = firstLine.length - firstLine.replace(/^\s*/g, '').length,
        indent
      ;
      if(leadingSpaces !== 0) {
        indent = leadingSpaces;
      }
      else {
        // string has already been trimmed, get first indented line and subtract 2
        $.each(lines, function(index, line) {
          leadingSpaces = line.length - line.replace(/^\s*/g, '').length;
          if(leadingSpaces !== 0) {
            indent = leadingSpaces - spacesPerIndent;
            return false;
          }
        });
      }
      return indent || 4;
    },

    createAnnotation: function() {
      if(!$(this).data('type')) {
        $(this).data('type', 'html');
      }
      $(this)
        .wrap('<div class="annotation">')
        .parent()
        .hide()
      ;
    },

    resizeCode: function() {
    },

    makeCode: function() {
    },

    makeStickyColumns: function() {
      var
        $visibleStuck = $(this).find('.fixed.column .image, .fixed.column .content'),
        isInitialized = ($visibleStuck.parent('.sticky-wrapper').size() !== 0)
      ;
      if(!isInitialized) {
        $visibleStuck
          .waypoint('sticky', {
            offset     : 65,
            stuckClass : 'fixed'
          })
        ;
      }
      // apparently this doesnt refresh on first hit
      $.waypoints('refresh');
      $.waypoints('refresh');
    },

    movePeek: function() {
      if( $('.stuck .peek').size() > 0 ) {
        $('.peek')
          .toggleClass('pushed')
        ;
      }
      else {
        $('.peek')
          .removeClass('pushed')
        ;
      }
    },

    menu: {
      mouseenter: function() {
        $(this)
          .stop()
          .animate({
            width: '155px'
          }, 300, function() {
            $(this).find('.text').show();
          })
        ;
      },
      mouseleave: function(event) {
        $(this).find('.text').hide();
        $(this)
          .stop()
          .animate({
            width: '70px'
          }, 300)
        ;
    }

    },

    peek: function() {
      var
        $body     = $('html, body'),
        $header   = $(this),
        $menu     = $header.parent(),
        $group    = $menu.children(),
        $headers  = $group.add( $group.find('.menu .item') ),
        $waypoint = $waypoints.eq( $group.index( $header ) ),
        offset
      ;
      offset    = $waypoint.offset().top - 70;
      if(!$header.hasClass('active') ) {
        $menu
          .addClass('animating')
        ;
        $headers
          .removeClass('active')
        ;
        $body
          .stop()
          .one('scroll', function() {
            $body.stop();
          })
          .animate({
            scrollTop: offset
          }, 500)
          .promise()
            .done(function() {
              $menu
                .removeClass('animating')
              ;
              $headers
                .removeClass('active')
              ;
              $header
                .addClass('active')
              ;
              $waypoint
                .css('color', $header.css('border-right-color'))
              ;
              $waypoints
                .removeAttr('style')
              ;
            })
        ;
      }
    },

    peekSub: function() {
      var
        $body           = $('html, body'),
        $subHeader      = $(this),
        $header         = $subHeader.parents('.item'),
        $menu           = $header.parent(),
        $subHeaderGroup = $header.find('.item'),
        $headerGroup    = $menu.children(),
        $waypoint       = $('h2').eq( $headerGroup.index( $header ) ),
        $subWaypoint    = $waypoint.nextAll('h3').eq( $subHeaderGroup.index($subHeader) ),
        offset          = $subWaypoint.offset().top - 80
      ;
      $menu
        .addClass('animating')
      ;
      $headerGroup
        .removeClass('active')
      ;
      $subHeaderGroup
        .removeClass('active')
      ;
      $body
        .stop()
        .animate({
          scrollTop: offset
        }, 500, function() {
          $menu
            .removeClass('animating')
          ;
          $subHeader
            .addClass('active')
          ;
        })
        .one('scroll', function() {
          $body.stop();
        })
      ;
    },

    swapStyle: function() {
      var
        theme = $(this).data('theme')
      ;
      $(this)
        .addClass('active')
        .siblings()
          .removeClass('active')
      ;
      $('head link.ui')
        .each(function() {
          var
            href         = $(this).attr('href'),
            subDirectory = href.split('/')[3],
            newLink      = href.replace(subDirectory, theme)
          ;
          $(this)
            .attr('href', newLink)
          ;
        })
      ;
    }
  };

  $(window)
    .on('resize', function() {
      clearTimeout(handler.timer);
      handler.timer = setTimeout(handler.resizeCode, 100);
    })
  ;

  $downloadDropdown
    .dropdown({
      on         : 'click',
      transition : 'scale'
    })
  ;

  // attach events
  if($.fn.tablesort !== undefined) {
    $sortTable
      .tablesort()
    ;
  }

  if( $pageTabs.size() > 0 ) {
    $pageTabs
      .tab({
        onTabInit : handler.makeCode,
        onTabLoad : function() {
          $.proxy(handler.makeStickyColumns, this)();
          $peekItem.removeClass('active').first().addClass('active');
        }
      })
    ;
  }
  else {
    handler.makeCode();
  }


  handler.createIcon();

  $helpPopup
    .popup()
  ;

  $swap
    .on('click', handler.swapStyle)
  ;

  $increaseFont
    .on('click', handler.font.increase)
  ;
  $decreaseFont
    .on('click', handler.font.decrease)
  ;

  $menuPopup
    .popup({
      position   : 'bottom center',
      className: {
        popup: 'ui popup'
      }
    })
  ;
  $sortableTables
    .tablesort()
  ;

  $menuDropdown
    .dropdown({
      on         : 'hover',
      action     : 'nothing'
    })
  ;

  $sidebarButton
    .on('mouseenter', handler.menu.mouseenter)
    .on('mouseleave', handler.menu.mouseleave)
  ;
  $menu
    .sidebar('attach events', '.launch.button, .launch.item')
    .sidebar('attach events', $hideMenu, 'hide')
  ;
  $waypoints
    .waypoint({
      continuous : false,
      offset     : 100,
      handler    : function(direction) {
        var
          index = (direction == 'down')
            ? $waypoints.index(this)
            : ($waypoints.index(this) - 1 >= 0)
              ? ($waypoints.index(this) - 1)
              : 0
        ;
        $peekItem
          .removeClass('active')
          .eq( index )
            .addClass('active')
        ;
      }
    })
  ;
  $('body')
    .waypoint({
      handler: function(direction) {
        if(direction == 'down') {
          if( !$('body').is(':animated') ) {
            $peekItem
              .removeClass('active')
              .eq( $peekItem.size() - 1 )
                .addClass('active')
            ;
          }
        }
      },
      offset: 'bottom-in-view'
     })
  ;
  $peek
    .waypoint('sticky', {
      offset     : 85,
      stuckClass : 'stuck'
    })
  ;

  $peekItem
    .on('click', handler.peek)
  ;
  $peekSubItem
    .on('click', handler.peekSub)
  ;

};


// attach ready event
$(document)
  .ready(semantic.ready)
;
