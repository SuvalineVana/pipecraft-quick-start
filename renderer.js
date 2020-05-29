// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
window.$ = window.jQuery = require('jquery');
var child_process = require('child_process');
const { dialog } = require('electron').remote
const fs = require('fs')


function TruncateEnvFile(serviceName){
  envFilePath = 'env_files/' + serviceName + '.env'
  fs.readFile(envFilePath, function (err, data) {
    if (err) throw err;
    theFile = data.toString().split("\n");
    theFile.splice(-3, 3);
    fs.writeFile('script_folder/SetupTest.sh', theFile.join("\n"), function (err) {
        if (err) {
            return console.log(err);
        }
        // console.log("Removed last 3 lines");
        // console.log(theFile.length);
    });
  });
}

function AppendToEnvFile(env_variable, serviceName){
  envFilePath = 'env_files/' + serviceName + '.env'
  line2append = env_variable + '\n'
  fs.appendFile(envFilePath, line2append, function (err) {
    if (err) {
      // append failed
    } else {
      // done
    }
  })
}


// materialize-css


$(document).ready(function() {
  $('input#input_text, textarea#textarea2').characterCounter();
});

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

// Switch view
  // Home screen
var newView = $('#PlutoTwitter')
$(newView).fadeIn( 500, function(){
});

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
  // Show PlutoF Twitter if all steps are removed
  if (document.querySelectorAll("#SelectedSteps li").length < 1) {
    // array does not exist, is not an array, or is empty
    // ⇒ do not attempt to process array
    console.log("tere")
    newView = $('#PlutoTwitter')
    $(newView).fadeIn( 500, function(){
    });
  }

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