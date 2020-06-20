// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
window.$ = window.jQuery = require('jquery');
const { dialog } = require('electron').remote
const fs = require('fs');
// const {exec} = require('child_process');
// const { sync } = require('child_process');
const { spawnSync } = require('child_process')
const {spawn} = require('child_process');
let Shell2 = require('node-powershell-await');


// ENV file management functions
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

// Home screen
var newView = $('#PlutoTwitter')
$(newView).fadeIn( 500, function(){
});

// Switch view
function switchView() {
  
  viewSelector = ('.wrapper.').concat($(this).parent().attr("class").replace(' ','.'))
  oldview = newView
  newView = $(viewSelector)
  // console.log(viewSelector)
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
    cbGroupName = view.attr('class')
    view.find(':checkbox').attr("name", cbGroupName);
    console.log(view.find(':checkbox'))
    console.log(view.attr('class'))

    i++
    // Do not collapse if checkbox is clicked
    $(".not-collapse").on("click", function(e) { e.stopPropagation(); });


    // Allow only 1 checkbox to be checked
    $('input[type="checkbox"]').on('change', function() {
      $('input[name="' + this.name + '"]').not(this).prop('checked', false);
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
function writeLog(serviceName, runLog){
  logName = 'logs/' + serviceName +'_log.txt'
  fs.writeFile(logName, runLog, function(err) {
    if(err) {
        return console.log(err);
    }
    console.log("The file was saved!");
}); 
}

function execShellCommand(cmd) {
  const exec = require('child_process').exec;
  return new Promise((resolve, reject) => {
   exec(cmd, (error, stdout, stderr) => {
    if (error) {
     console.warn(error);
     serviceError = cmd.split(" ").slice(-1) + '-error'
     writeLog(serviceError, error)
    }
    resolve(stdout? stdout : stderr);
   });
  });
}

async function RunDockerCompose(serviceName){
  const runLog = await execShellCommand('docker-compose run ' + serviceName);
  console.log(runLog);
  writeLog(serviceName, runLog)
}

function collectParams(WorkFlowTag){
  serviceName = ""
  $(WorkFlowTag).find(':checkbox').each(function(){
    if (this.checked == true){
      serviceName = $(this).parent().attr("value")
      console.log(serviceName)
      return serviceName
    }
  })
}

async function processStepsInfo(workFlowSteps){
  for (const item of workFlowSteps) {
    WorkFlowTag = ('.wrapper.' + item.closest('li').getAttribute('class').replace(' ','.'))
    console.log(WorkFlowTag)
    collectParams(WorkFlowTag)
    if (serviceName == ""){
      console.log('No steps selected')
      break
    }
    await RunDockerCompose(serviceName)
    console.log('Log collection function should go here')
    console.log('Incase of an error, break loop here and Alert User')
  }
}

// Run Button
$('#runButton').click(async function(){
  workFlowSteps = $(".viewSwitch");
  await processStepsInfo(workFlowSteps);
  console.log('The whole workflow has completed: Show user stats and save configuration file')
})


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