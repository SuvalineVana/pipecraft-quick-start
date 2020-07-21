// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.
window.$ = window.jQuery = require('jquery');
const { dialog } = require('electron').remote
const fs = require('fs');
const { spawnSync } = require('child_process')
const {spawn} = require('child_process');
let Shell2 = require('node-powershell-await');
const path = require('path');
const { BrowserWindow } = require('electron').remote
const PDFWindow = require('electron-pdf-window')
var url = require('url');
const { clear } = require('console');
const replace = require('replace-in-file');

// materialize-css

$(document).ready(function(){
  $('.tooltipped').tooltip();
});

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

//// FUNCTIONS
// Open pdf manual
function openManual(manualName) {
  const win = new BrowserWindow({ width: 1200, height: 800 })
  PDFWindow.addSupport(win)
  console.log(path.join(__dirname, '/manuals/' + manualName))
  manualPath = path.join(__dirname, '/manuals/' + manualName)
  win.loadURL(manualPath)
}

// Append a env_variable to service env file
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

// Clear line from .env file
async function clearEnvLine(line){
  const line2clear = new RegExp(line + '.*', 'g')
  const options = {
  files: '.env',
  from: line2clear,
  to: '',
}
  try {
    const results = await replace(options)
    console.log('Replacement results:', results)
  }
  catch (error) {
    console.error('Error occurred:', error)
  }
}

function writeLog(serviceName, runLog){
  logName = 'logs/' + serviceName +'_log.txt'
  fs.writeFile(logName, runLog, function(err) {
    if(err) {
        return console.log(err);
    }
    console.log('output written to: ' + logName);
}); 
}

function execShellCommand(cmd) {
  const exec = require('child_process').exec;
  return new Promise((resolve, reject) => {
   exec(cmd, (error, stdout, stderr) => {
    if (error) {
     console.warn(error);
     alert(error)
     serviceError = cmd.split(" ").slice(-1) + '-error'
     writeLog(serviceError, error)
    }
    resolve(stdout? stdout : stderr);
   });
  });
}

//Show extra options
$('body').on('click', '.extraOptionsTrigger', function () {
  if ($(this).text() == 'Show more options') {
    $(this).text("Show less options")
  } else {
    $(this).text("Show more options")
  }
  $(this).siblings(".extraOptions").toggle()
  console.log($(this).text())
})

//Show PDF manual with electron
$('body').on('click', '.manualLink', function () {
  manualName = $(this).attr('id')
  console.log(manualName);
  openManual(manualName)
});

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
var i = 1
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
    view.find('.serviceCB').attr("name", cbGroupName);
    console.log(view.find(':checkbox'))
    console.log(view.attr('class'))

    // Disable dropdown options until removed
    $(this).find( "a" ).css( "color", "#ECEFF0" )
    $(this).find( "a" ).css( "background-color", "#BAB8BA" )
    $(this).find( "i" ).remove()
    $(this).addClass("disabled")

    i++
    // Do not collapse if checkbox is clicked
    $(".not-collapse").on("click", function(e) { e.stopPropagation(); });


    // Allow only 1 checkbox to be checked per step
    $('input[type="checkbox"]').on('change', function() {
      // console.log(this.name)
      // console.log($('input[name="' + this.name + '"]'))
      $('input[name="' + this.name + '"]').not(this).prop('checked', false);
    });
    
  })  
})

// Remove workflow steps
$( "#SelectedSteps" ).on( "click", "i", function( event ) {
  event.preventDefault();

  // Enable in dropdown
  classToEnable =$(this).parent().parent().attr('class').split(' ')[0]
  console.log(classToEnable)
  console.log($('.disabled.'+classToEnable))
  $('.disabled.'+classToEnable).find( "a" ).css( "color", "black" )
  $('.disabled.'+classToEnable).find( "a" ).css( "background-color", "transparent" )
  
  var materialIcon = document.createElement('i');
  materialIcon.className = 'material-icons';
  var materialIconAdd = document.createTextNode('add_circle_outline');
  materialIcon.appendChild(materialIconAdd);

  $('.disabled.'+classToEnable).find( "a" )[0].appendChild(materialIcon)
  $('.disabled.'+classToEnable).removeClass('disabled')
   // $('.disabled.'+classToEnable).addClass('dropdown-slection')
  // $('.dropdown-selection.'+classToEnable).find( "a" ).css( "color", "red" )
  // $('.dropdown-selection.'+classToEnable).find( "a" ).css( "background-color", "white" )


  viewTag = ('.wrapper.' + ($(this).closest('li').attr('class'))).replace(' ', '.')
  $(viewTag).remove()
  $(this).closest('li').remove();
  // Show PlutoF Twitter if all steps are removed
  if (document.querySelectorAll("#SelectedSteps li").length < 1) {
    // array does not exist, is not an array, or is empty
    // ⇒ do not attempt to process array
    newView = $('#PlutoTwitter')
    $(newView).fadeIn( 500, function(){
    });
  }

});

// Select input folder and save as env variable
const fileSelectButton = document.getElementById('FileSelectButton');
fileSelectButton.addEventListener('click', async function(){
    //Clear previos inputfolder from .env file
    clearEnvLine('sisend_kaust')
    // Open windows file dialog
    dialog.showOpenDialog({
        properties: ['openDirectory', 'showHiddenFiles']
      }).then(result => {
        inputPathEnv = 'sisend_kaust=' + result.filePaths[0] +"\r\n"
        console.log(inputPathEnv)
        // Append folder path as a variable to .env file
        fs.appendFile('.env', inputPathEnv, function (err) {
          if (err) {
            console.log('append failed')
          } else {
            console.log('input folder added')
          }
        })
      }).catch(err => {
        console.log(err)
      })
})

// Run Analysis
// Setup

async function processStepsInfo(workFlowSteps){
  for (const item of workFlowSteps) {
    WorkFlowTag = ('.wrapper.' + item.closest('li').getAttribute('class').replace(' ','.'))
    await collectParams(WorkFlowTag)
    await RunDockerCompose(serviceName)
    // Place to pause for step-by-step mode
  }
}


async function RunDockerCompose(serviceName){
  console.log("Starting step")
  console.log(serviceName)
  const runLog = await execShellCommand('docker-compose run ' + serviceName);
  console.log(runLog);
  clearEnvLine('workdir')
  workDirPathEnv = 'workdir=/input/' + serviceName + '-output' +"\r\n"
  console.log(workDirPathEnv)  
  fs.appendFile('.env', workDirPathEnv, function (err) {
    if (err) {
    } else {
    }
  })
  writeLog(serviceName, runLog)
}

async function collectParams(WorkFlowTag){
  serviceName = ""
  // Find selected service
  $(WorkFlowTag).find('.serviceCB').each(async function(){
    if (this.checked == true){
      serviceName = $(this).parent().attr("value")
      console.log(serviceName)
      envFileToClear= 'env_files/' + serviceName + '.env'
      fs.truncate(envFileToClear, 0, function(){console.log('env file ready')})
      return serviceName
    }
  })
  // Capture numeric input
  $(WorkFlowTag).find("#" + serviceName).find('.InlineNumericInput').each(function(){
    if ($(this)[0].value !== "") {
      env_variable = $(this).attr('id').replace(/[ -=,]/g, '')+'='+$(this).attr('id')+$(this)[0].value
      console.log(env_variable)
      AppendToEnvFile(env_variable, serviceName)
    } else {
      env_variable = $(this).attr('id').replace(/[ -=,]/g, '')+'= '
      console.log(env_variable)
      AppendToEnvFile(env_variable, serviceName)
    }
  })
  // Capture ON/OFF input
  $(WorkFlowTag).find("#" + serviceName).find('.onOff').each(function(){
    if ($(this).is(':checked')) {
      env_variable = $(this).attr('id').replace(/[ -=,]/g, '')+'=ON'
      console.log(env_variable)
      AppendToEnvFile(env_variable, serviceName)
    } else {
      env_variable = $(this).attr('id').replace(/[ -=,]/g, '')+'=OFF'
      console.log(env_variable)
      AppendToEnvFile(env_variable, serviceName)
    }
  })
  console.log("All env variables written")
}

// Run Button
$('#runButton').click(async function(){

  $("div.spanner").addClass("show")
  $("div.overlay").addClass("show")

  await clearEnvLine('workdir')
  defaultWorkDir = "workdir=/input" +"\r\n"
  fs.appendFile('.env', defaultWorkDir, function (err) {
    if (err) {
    } else {
    }
  })

  workFlowSteps = $(".viewSwitch");
  console.log(workFlowSteps)
  await processStepsInfo(workFlowSteps);
  configSteps = $( "#SelectedSteps" )
  for (i=0; i < configSteps.length; i++) {
    console.log(configSteps[i])
  }
  console.log('The whole workflow has completed: Show user stats and save configuration file')

  $("div.spanner").removeClass("show")
  $("div.overlay").removeClass("show")
})


