// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

//Switching views

const { dialog } = require('electron').remote
var child_process = require('child_process');
var newView = '.startingView'

$( ".nav-link" ).click(function() {
    Oldview = newView
    newView = '.' + $(this).attr('id')  
    $(Oldview).fadeOut( 250, function() {
      $(newView).fadeIn( 250, function(){
      });
    });
  });
// nav switch

$("#test").click(function(){
  $("#fileSelect").click()
  $("#mainNav, #altNav").toggleClass("hideView")
})


  $('input').click(function() {
    var barId = '#' + $(this).attr('id') + 'Bar' 
    $(barId).toggleClass("bg-success progress-bar-animated")
    $(barId).toggleClass("bg-dark")
});


const fileSelectButton = document.getElementById('selectFiles');
fileSelectButton.addEventListener('click', function(){
    dialog.showOpenDialog({
        properties: ['openFile', 'multiSelections',]
      }).then(result => {
        console.log(result.canceled)
        pythonPathParameter = result.filePaths[0]
        console.log(result.filePaths)
        console.log(result)
      }).catch(err => {
        console.log(err)
      })
})

const runButton = document.getElementById('Run');
runButton.addEventListener('click', function(){
  child_process.execSync(file);
  console.log('done')
})