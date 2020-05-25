// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
window.$ = window.jQuery = require('jquery');
var child_process = require('child_process');
const { dialog } = require('electron').remote
// materialize-css

$(document).ready(function(){
  $('.sidenav').sidenav();
  $('.sidenav').sidenav('open')
});

$(document).ready(function(){
  $('.collapsible').collapsible();
});
document.addEventListener('DOMContentLoaded', function() {
  var elems = document.querySelectorAll('.dropdown-trigger');
  var instances = M.Dropdown.init(elems);
});

$( function() {
  $( "#SelectedSteps" ).sortable();
  $( "#SelectedSteps" ).disableSelection();
});

// Jquery-ui
$( function() {
  $( document ).tooltip({
    position: { at: "center-75 top-70"}
  });
} );
var i = 1

// // Switch view
var newView = ''
function switchView() {
  
  viewSelector = ('.wrapper.').concat($(this).parent().attr("class").replace(' ','.'))
  oldview = newView
  newView = $(viewSelector)
  console.log(viewSelector)
  // $(viewSelector).toggleClass('hideView')
  $(oldview).fadeOut( 250, function() {
    $(newView).fadeIn( 250, function(){
    });
  });  
}

// Add workflow steps
$('.dropdown-selection').each(function(){
  $(this).click(function(){

    var step = $(this).clone().removeClass('dropdown-selection')
    step.find('i').text('remove_circle_outline').addClass('RemoveButtons')
    step.find('a').addClass('viewSwitch')
    step.on('click', 'a', switchView)
    
    
    var viewClass = '.wrapper.blank.' + $(this).removeClass('dropdown-selection').attr('class')
    var view = $(viewClass).clone().removeClass('blank')
    
    step.addClass(i.toString())
    view.addClass(i.toString())
    step.appendTo('#SelectedSteps')
    view.appendTo('body')
    M.AutoInit();

    i++
    // Do not collapse if checkbox is clicked
    $(".not-collapse").on("click", function(e) { e.stopPropagation(); });


    // Allow only 1 checkbox to be checked
    $('input[type="checkbox"]').on('change', function() {
      $('input[type="checkbox"]').not(this).prop('checked', false);
    });
    
  })  
})

// Remove workflow steps
$( "#SelectedSteps" ).on( "click", "i", function( event ) {
  event.preventDefault();
  viewTag = ('.wrapper.' + ($(this).closest('li').attr('class'))).replace(' ', '.')
  $(viewTag).remove()
  $(this).closest('li').remove();
});


// Run Analysis

// Setup
const path = require('path');
const compose =require('docker-compose')

function runService(serviceName){
  compose.upOne(serviceName,{ cwd: path.join(__dirname), log: true })
  .then(
    () => { console.log('done')},
    err => { console.log('something went wrong:', err.message)}
  );
}

// On click execute docker services 

$('#runButton').click(function(){
  $(".viewSwitch").each(function(index){
    console.log('nr '+ index +' in run order')
    dockerInputTag = ('.wrapper.' + $(this).parent().attr('class').replace(' ', '.'))
    console.log($(this).parent().attr('class'))
    console.log($(dockerInputTag))
    // $(dockerInputTag).find(':checkbox').each(function(){
    //   console.log($(this).parent.attr("name"))
    // })
    console.log(index)
    // runService('cutadapt')
    // runService('mothur')
    // child_process.execSync('docker-compose run cutadapt')
  })
})

// Do not collapse if checkbox is clicked
$(".not-collapse").on("click", function(e) { e.stopPropagation(); });


// Allow only 1 checkbox to be checked
$('input[type="checkbox"]').on('change', function() {
  $('input[type="checkbox"]').not(this).prop('checked', false);
});


// Select input files and write them to a list

const fileSelectButton = document.getElementById('FileSelectButton');
fileSelectButton.addEventListener('click', function(){
    dialog.showOpenDialog({
        properties: ['openFile', 'multiSelections',]
      }).then(result => {
        InputFileList = result.filePaths
        console.log(result.filePaths)
      }).catch(err => {
        console.log(err)
      })
})


// var spawn = require('child_process').spawn;
// var cp = spawn(process.env.comspec, ['/c', 'dir', '-arg1', '-arg2']);

// cp.stdout.on("data", function(data) {
//     console.log(data.toString());
// });

// cp.stderr.on("data", function(data) {
//     console.error(data.toString());
// });

// const runButton = document.getElementById('Run');
// runButton.addEventListener('click', function(){
//   child_process.exec('docker run --rm -ti hello-world');
//   child_process.execSync('docker-compose run cutadapt cutadapt/Mi_seq_ITS.sh');
//   console.log('done')
// })