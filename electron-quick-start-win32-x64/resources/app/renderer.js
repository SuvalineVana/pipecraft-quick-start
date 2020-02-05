// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

//Switching views



var newView = '.startingView'

$( ".nav-link" ).click(function() {
    Oldview = newView
    newView = '.' + $(this).attr('id')  
    $(Oldview).fadeOut( 200, function() {
      $(newView).fadeIn( 200, function(){
      });
    });
  });


  $('input').click(function() {
    var barId = '#' + $(this).attr('id') + 'Bar' 
    $(barId).toggleClass("bg-success progress-bar-animated")
    $(barId).toggleClass("bg-dark")
});