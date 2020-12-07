// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

window.$ = window.jQuery = require("jquery");
const Swal = require("sweetalert2");
var vex = require("vex-js");
vex.registerPlugin(require("vex-dialog"));
vex.defaultOptions.className = "vex-theme-os";
const prompt = require("electron-prompt");
const { dialog } = require("electron").remote;
const fs = require("fs");
const { spawnSync } = require("child_process");
const { spawn } = require("child_process");
let Shell2 = require("node-powershell-await");
const path = require("path");
const { BrowserWindow } = require("electron").remote;
const PDFWindow = require("electron-pdf-window");
var url = require("url");
const { clear } = require("console");
const replace = require("replace-in-file");
let inputFilesArray = [];
let inputFilesArraryEnv = ""
let forwardPrimerArray = [];
let reversePrimerArray = [];
let numericInputs = {};
let checkedServices = {};
let steps = [];
let onOffInputs = {};
let conf2Save = [];
let readType = ""
let dataFormat = ""
let fileExtension = ""
const { Menu, MenuItem } = require("electron").remote;
const slash = require("slash");
const ipc = require("electron").ipcRenderer


// Terminal Window
// const { Terminal } = require("xterm");
var term = new Terminal({
  theme: { background: 'linear-gradient(to right, #0f2027, #203a43, #2c5364)', foreground: '#fffff' },
  rows: 20,
  cols: 100,
});
term.open(document.getElementById("terminal"))
// term.write("hello")
term.onData(e => {
  ipc.send("terminal.toTerm", e);
});

ipc.on("terminal.incData", function(event, data){
  term.write(data);
})

// materialize-css


document.addEventListener("DOMContentLoaded", function () {
  var elems = document.querySelectorAll(".tap-target");
  var instances = M.TapTarget.init(elems, options);
});

document.addEventListener('DOMContentLoaded', function() {
  var elems = document.querySelectorAll('select');
  var instances = M.FormSelect.init(elems, options);
});

$(document).ready(function () {
  $(".tap-target").tapTarget();
});

document.addEventListener('DOMContentLoaded', function() {
  var elems = document.querySelectorAll('.chips');
  var instances = M.Chips.init(elems, options);
});


document.addEventListener("DOMContentLoaded", function () {
  var elems = document.querySelectorAll(".tooltipped");
  var instances = M.Tooltip.init(elems, options);
});


$(document).ready(function () {
  $(".sidenav").sidenav();
  $(".sidenav").sidenav("open");
});

$(document).ready(function () {
  $(".collapsible").collapsible();
});

document.addEventListener("DOMContentLoaded", function () {
  var elems = document.querySelectorAll(".dropdown-trigger");
  var instances = M.Dropdown.init(elems);
});

$(function () {
  $("#SelectedSteps").sortable();
  $("#SelectedSteps").disableSelection();
});

// Custom titlebar and menu
const menu1 = new Menu();

menu1.append(
  new MenuItem({
    // label: 'Documentation',
    // submenu: [
    // 	{
    // 		label: 'pdf',
    // 		click: () => console.log('Click on subitem 1')
    // 	},
    // 	{
    // 		type: 'separator'
    //   },
    //   {
    // 		label: 'online',
    // 		click: () => console.log('Click on subitem 1')
    // 	}
    // ]
  })
);

const customTitlebar = require("custom-electron-titlebar");
const { RGBA } = require("custom-electron-titlebar");
new customTitlebar.Titlebar({
  backgroundColor: customTitlebar.Color.fromHex("#757575"),
  menu: menu1,
  maximizable: false,
  titleHorizontalAlignment: "center",
});

//// FUNCTIONS

// restrict certain chars AND keyCodes jQuery plugin by David Hellsing
$.fn.restrict = function( chars ) {
  return this.keydown(function(e) {
      var found = false, i = -1;
      while(chars[++i] && !found) {
          found = chars[i] == String.fromCharCode(e.which).toLowerCase() || 
                  chars[i] == e.which;
      }
      if (!found) { e.preventDefault(); }
  });
};
  

//Load a previous or an external configuration via JSON
function loadConfiguration(configLoadPath) {
  //Read and parse
  let rawdata = fs.readFileSync(configLoadPath);
  let configObj = JSON.parse(rawdata);
  var steps = configObj[0];
  var checkedServices = configObj[1];
  var numericInputs = configObj[2];
  var onOffInputs = configObj[3];
  // Load configuration steps
  StepsToClear = document.querySelectorAll("#SelectedSteps > li > a > i");
  for (var y = 0; y < StepsToClear.length; y++) {
    StepsToClear[y].click();
  }
  for (z = 0; z < steps.length; z++) {
    document.querySelector(".dropdown-selection." + steps[z]).click();
  }
  // Check configuration services
  for (const [sName, onValue] of Object.entries(checkedServices)) {
    if (
      $("label[value=" + sName + "]>input[name*=wrapper]").prop("checked") ==
      false
    ) {
      document
        .querySelector("label[value=" + sName + "]>input[name*=wrapper]")
        .click();
    }
  }
  // Load numeric inputs
  for (const [key, value] of Object.entries(numericInputs)) {
    var sName = key.split("|")[0];
    var nrID = key.split("|")[1];
    $(".wrapper:not(.blank)")
      .find("#" + sName)
      .find('[id="' + nrID + '"]')
      .prop("value", value);
  }
  // Load binary inputs (on/off) switches
  for (const [key, value] of Object.entries(onOffInputs)) {
    var sName = key.split("|")[0];
    var nrID = key.split("|")[1];
    console.log(sName, nrID, value);
    $(".wrapper:not(.blank)")
      .find("#" + sName)
      .find('[id="' + nrID + '"]')
      .prop("checked", value);
  }
}

function saveConfiguration() {
  // Clear configuration objects
  for (var member in numericInputs) delete numericInputs[member];
  for (var member in checkedServices) delete checkedServices[member];
  for (var member in onOffInputs) delete onOffInputs[member];
  for (var member in conf2Save) delete conf2Save[member];
  steps.length = 0;
  console.log(conf2Save);
  // Save configuration steps
  configSteps = $("#SelectedSteps > li");
  for (i = 0; i < configSteps.length; i++) {
    steps[i] = configSteps.eq(i).attr("class").split(" ")[0];
  }
  // Save configuration services
  workFlowSteps = $(".viewSwitch");
  for (const item of workFlowSteps) {
    WorkFlowTag =
      ".wrapper." + item.closest("li").getAttribute("class").replace(" ", ".");
    $(WorkFlowTag)
      .find(".serviceCB")
      .each(function () {
        if (this.checked == true) {
          serviceSave = $(this).parent().attr("value");
          checkedServices[serviceSave] = true;
          $(WorkFlowTag)
            .find("#" + serviceSave)
            .find(".InlineNumericInput")
            .each(function () {
              numericInputs[serviceSave + "|" + $(this).attr("id")] = $(
                this
              )[0].value;
            });
          $(WorkFlowTag)
            .find("#" + serviceSave)
            .find(".onOff")
            .each(function () {
              onOffInputs[serviceSave + "|" + $(this).attr("id")] = $(
                this
              ).prop("checked");
            });
        }
      });
  }

  if (steps.length < 1) {
    alert("No steps selected");
    return event.preventDefault();
  }
  if (steps.length != Object.keys(checkedServices).length) {
    alert("A software must be checked for each step, remove unused steps");
    return false;
  }

  conf2Save.push(steps);
  conf2Save.push(checkedServices);
  conf2Save.push(numericInputs);
  conf2Save.push(onOffInputs);
}

// Open pdf manual
function openManual(manualName) {
  const win = new BrowserWindow({ width: 1200, height: 800 });
  PDFWindow.addSupport(win);
  console.log(path.join(__dirname, "/manuals/" + manualName));
  manualPath = path.join(__dirname, "/manuals/" + manualName);
  win.loadURL(manualPath);
}

// Append a env_variable to service env file
function AppendToEnvFile(env_variable, serviceName) {
  envFilePath = "env_files/" + serviceName + ".env";
  line2append = env_variable + "\n";
  fs.appendFile(envFilePath, line2append, function (err) {
    if (err) {
      // append failed
    } else {
      // done
    }
  });
}

// Clear line from .env file
async function clearEnvLine(line) {
  const line2clear = new RegExp(line + ".*\n", "g");
  const options = {
    files: ".env",
    from: line2clear,
    to: "",
  };
  try {
    const results = await replace(options);
  } catch (error) {
    console.error("Error occurred:", error);
  }
}

function writeLog(serviceName, runLog) {
  logName = "logs/" + serviceName + "_log.txt";
  fs.writeFile(logName, runLog, function (err) {
    if (err) {
      return console.log(err);
    }
    console.log("output written to: " + logName);
  });
}

function execShellCommand(cmd) {
  const exec = require("child_process").exec;
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        console.warn(error);
        alert(error);
        serviceError = cmd.split(" ").slice(-1) + "-error";
        writeLog(serviceError, error);
      }
      resolve(stdout ? stdout : stderr);
    });
  });
}

//Show extra options
$("body").on("click", ".extraOptionsTrigger", function () {
  if ($(this).text() == "Show more options") {
    $(this).text("Show less options");
  } else {
    $(this).text("Show more options");
  }
  $(this).siblings(".extraOptions").toggle();
  console.log($(this).text());
});

//Show PDF manual with electron
$("body").on("click", ".manualLink", function () {
  manualName = $(this).attr("id");
  console.log(manualName);
  openManual(manualName);
});

// Home screen
var newView = $("#PlutoTwitter");
$(newView).fadeIn(500, function () {});

// Switch view
function switchView() {
  viewSelector = ".wrapper.".concat(
    $(this).parent().attr("class").replace(" ", ".")
  );
  oldview = newView;
  newView = $(viewSelector);
  // console.log(viewSelector)
  // $(viewSelector).toggleClass('hideView')
  $(oldview).fadeOut(250, function () {
    $(newView).fadeIn(250, function () {});
  });
}


// Add workflow steps
var i = 1;
$(".dropdown-selection").each(function () {
  $(this).click(function () {
    if ($(".activated")[0]){
      StepsToClear = document.querySelectorAll("#SelectedSteps > li > a > i");
      for (var y = 0; y < StepsToClear.length; y++) {
        StepsToClear[y].click();
      }
    }
    var step = $(this).clone().removeClass("dropdown-selection");
    step.find("i").text("remove_circle_outline").addClass("RemoveButtons");
    step.find("a").addClass("viewSwitch");
    step.on("click", "a", switchView);

    var viewClass =
      ".wrapper.blank." +
      $(this).clone().removeClass("dropdown-selection").attr("class");
    var view = $(viewClass).clone().removeClass("blank");

    step.addClass(i.toString());
    view.addClass(i.toString());
    step.appendTo("#SelectedSteps");
    view.appendTo("body");
    M.AutoInit();
    cbGroupName = view.attr("class");
    view.find(".serviceCB").attr("name", cbGroupName);
    $(".container-after-titlebar").append(view);

    // Disable dropdown options until removed
    $(this).find("a").css("color", "#ECEFF0");
    $(this).css("background-color", "#BAB8BA");
    $(this).find("i").remove();
    $(this).addClass("disabled");

    i++;
    // Do not collapse if checkbox is clicked
    $(".not-collapse").on("click", function (e) {
      e.stopPropagation();
    });

    // Allow only 1 checkbox to be checked per step
    $('input[type="checkbox"].serviceCB').on("change", function () {
      $('input[name="' + this.name + '"]')
        .not(this)
        .prop("checked", false);
    });
  });
});

// Remove workflow steps
$("#SelectedSteps").on("click", "i", function (event) {
  event.preventDefault();

  // Enable in dropdown
  classToEnable = $(this).parent().parent().attr("class").split(" ")[0];
  $(".disabled." + classToEnable)
    .find("a")
    .css("color", "black");
  $(".disabled." + classToEnable).css("background-color", "transparent");

  var materialIcon = document.createElement("i");
  materialIcon.className = "material-icons";
  var materialIconAdd = document.createTextNode("add_circle_outline");
  materialIcon.appendChild(materialIconAdd);

  $(".disabled." + classToEnable)
    .find("a")[0]
    .appendChild(materialIcon);
  $(".disabled." + classToEnable).removeClass("disabled");

  viewTag = (".wrapper." + $(this).closest("li").attr("class")).replace(
    " ",
    "."
  );
  $(viewTag).remove();
  $(this).closest("li").remove();
  // Show PlutoF Twitter if all steps are removed
  if (document.querySelectorAll("#SelectedSteps li").length < 1) {
    // array does not exist, is not an array, or is empty
    // ⇒ do not attempt to process array
    newView = $("#PlutoTwitter");
    $(newView).fadeIn(500, function () {});
  }
});

$("#expertmode").on("click", function () {
  $(newView).fadeOut(250, function () {});
  $('#expertMode').fadeIn(250, function () {});
})

// Feature discovery setup
$("#stepmode").on("click", function () {
  if ($(".activated")[0]){
    // if class activated exists
    Swal.fire({
      text: "Switching to workflow-mode will clear all active configurations",
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Continue'
    }).then((result) => {
      if (result.isConfirmed) {
        document.getElementById("FileSelectButton").style.display = "block";
        document.getElementById("FileSelectButton2").style.display = "none";
        $('.StepModeButtonContainer').toggleClass("hideView")
        $(".demuxStepSelect").toggleClass("hideView")
        $('#stepmode').find('i').toggleClass('activated')
        console.log("single-step-mode deactivated");
        StepsToClear = document.querySelectorAll("#SelectedSteps > li > a > i");
        for (var y = 0; y < StepsToClear.length; y++) {
          StepsToClear[y].click();
        }
      }
    })
  } else {
    // class activated does not exist
    Swal.fire({
      text: "Switching to singe-step-mode will clear all active configurations",
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Continue'
    }).then((result) => {
      if (result.isConfirmed) {
        document.getElementById("FileSelectButton").style.display = "none";
        document.getElementById("FileSelectButton2").style.display = "block";
        $('.StepModeButtonContainer').toggleClass("hideView")
        $(".demuxStepSelect").toggleClass("hideView")
        $('#stepmode').find('i').toggleClass('activated')
        StepsToClear = document.querySelectorAll("#SelectedSteps > li > a > i");
        for (var y = 0; y < StepsToClear.length; y++) {
          StepsToClear[y].click();
        }
        console.log("single-step-mode activated");
      }
    })
  }
});


// Select input folder and save as env variable
const fileSelectButton = document.getElementById("FileSelectButton");
fileSelectButton.addEventListener("click", async function () {
  readType = ""
  dataFormat = ""
  fileExtension = ""
  Swal.mixin({
    input: "select",
    confirmButtonText: "Next &rarr;",
    showCancelButton: true,
    progressSteps: ["1", "2", "3"],
  })
    .queue([
      {
        title: "Sequencing read types",
        inputOptions: {
          singleend: "single-end",
          pairedend: "paired-end",
        },
      },
      {
        title: "Sequencing data format",
        inputOptions: {
          demulitplexed: "demulitplexed",
          multiplexed: "multiplexed",
        },
      },
      {
        title: "Sequence files extension",
        inputOptions: {
          'Uncompressed':{
            fastq: "*.fastq",
            fasta: "*.fasta",
            fq: "*.fq",
            fa: "*.fa",
            txt: "*.txt",
          },
          'Compressed':{
            fastqDOTgz: "*.fastq.gz",
            fastaDOTgz: "*.fasta.gz",
            fqDOTgz: "*.fq.gz",
            faDOTgz: "*.fa.gz",
            txtDOTgz: "*.txt.gz",
          },
        },
      },
    ])
    .then((result) => {
      if (result.value) {
        console.log(result);
        readType = result.value[0]
        dataFormat = result.value[1]
        fileExtension = result.value[2].replace("DOT", ".")
        if (result.value[1] == "multiplexed") {
          $('#SelectedSteps > .demultiplex').find('i').click()
          $(".dropdown-selection.demultiplex").click()
        }
        //Clear previos inputfolder from .env file
        clearEnvLine("userDir");
        // Open windows file dialog
        dialog
          .showOpenDialog({
            title: "Select the folder containing your sequnece files",
            properties: ["openDirectory", "showHiddenFiles"],
          })
          .then((result) => {
            inputPathEnv = "userDir=" + result.filePaths[0] + "\n";
            // Append folder path as a variable to .env file
            fs.appendFile(".env", inputPathEnv, function (err) {
              if (err) {
                console.log("append failed");
              } else {
                console.log(
                  "Local working directory set as: " + result.filePaths[0]
                );
              }
            });
          })
          .catch((err) => {
            console.log(err);
          });
      }
    });
});
// Select input folder and save as env variable
const fileSelectButton2 = document.getElementById("FileSelectButton2");
fileSelectButton2.addEventListener("click", async function () {
        //Clear previos inputfolder from .env file
        inputFilesArray = [];
        filepathString = "";
        inputFilesArraryEnv = ""
        await clearEnvLine("userDir");
        await clearEnvLine("inputFilesArray");
        await console.log(inputFilesArray)

        // Open windows file dialog
        dialog
          .showOpenDialog({
            title: "Select input files",
            properties: ["multiSelections", "showHiddenFiles"],
          })
          .then((result) => {
            inputPathEnv = "userDir=" + path.dirname(result.filePaths[0]) + "\n";
            xyz = result.filePaths
            console.log(xyz)
            for (var i=0; i < xyz.length; i++){
              console.log(xyz[i])
              inputFilesArray.push(path.basename(xyz[i]))
            }
            filepathString = JSON.stringify(inputFilesArray)
            filepathString = filepathString.replace(/","/g, '" "')
            filepathString = filepathString.replace(/\[/g, '(')
            filepathString = filepathString.replace(/\]/g, ')')
            console.log(filepathString)
            inputFilesArraryEnv = "inputFilesArray=" + filepathString + "\n";
            console.log(inputFilesArraryEnv)
            // Append folder path as a variable to .env file
            fs.appendFile(".env", inputPathEnv, function (err) {
              if (err) {
                console.log("append failed");
              } else {
                console.log(
                  "Local working directory set as: " +  path.dirname(result.filePaths[0])
                );
              }
            });
          })
          .catch((err) => {
            console.log(err);
          });
      })


// Save current configuration Button
const configSaveButton = document.getElementById("savecfg");
configSaveButton.addEventListener("click", async function () {
  saveConfiguration();
  if (steps.length < 1) {
    return false;
  }
  if (steps.length != Object.keys(checkedServices).length) {
    return false;
  }
  dialog
    .showSaveDialog({
      title: "Save current configuration",
      filters: [{ name: "JSON", extensions: ["JSON"] }],
    })
    .then((result) => {
      configSavePath = slash(result.filePath);
      console.log(configSavePath);
      let confJson = JSON.stringify(conf2Save);
      fs.writeFileSync(configSavePath, confJson);
    });
});

const configLoadButton = document.getElementById("loadcfg");
configLoadButton.addEventListener("click", async function () {
  dialog
    .showOpenDialog({
      title: "Select a previous configuration",
      filters: [{ name: "JSON", extensions: ["JSON"] }],
    })
    .then((result) => {
      configLoadPath = slash(result.filePaths[0]);
      console.log(configLoadPath);
      loadConfiguration(configLoadPath);
    });
});

// Run Analysis

async function processStepsInfo(workFlowSteps) {
  for (const item of workFlowSteps) {
    WorkFlowTag =
      ".wrapper." + item.closest("li").getAttribute("class").replace(" ", ".");
    await collectParams(WorkFlowTag);
    await RunDockerCompose(serviceName);
    // Place to pause for step-by-step mode
  }
}

async function RunDockerCompose(serviceName) {
  console.log("Starting step");
  console.log(serviceName);
  const runLog = await execShellCommand("docker-compose run " + serviceName);
  console.log(runLog);
  await clearEnvLine("workdir");
  workDirPathEnv = "workdir=/input/" + serviceName + "-output \n";
  fs.appendFile(".env", workDirPathEnv, function (err) {
    if (err) {
      console.log(err);
    } else {
      console.log("WorkingDir for next step is: " + workDirPathEnv);
    }
  });
  writeLog(serviceName, runLog);
}

async function collectParams(WorkFlowTag) {
  serviceName = "";
  // Find selected service
  $(WorkFlowTag)
    .find(".serviceCB")
    .each(async function () {
      if (this.checked == true) {
        serviceName = $(this).parent().attr("value");
        console.log(serviceName);
        envFileToClear = "env_files/" + serviceName + ".env";
        fs.truncate(envFileToClear, 0, function () {
          console.log("env file ready");
        });
        readTypeVariable = "readType=" + readType
        dataFormatVariable = "dataFormat=" + dataFormat
        fileExtensionVariable = "extension=" + fileExtension
        // barcodes_file=$",oligos=/input/oligos_paired.txt"
        oligosFileVariable = "barcodes_file=,oligos=/userdatabase/" + userDatabaseFile
        // AppendToEnvFile(inputFilesArraryEnv, serviceName)
        // AppendToEnvFile(forwardPrimerArrayEnv, serviceName)
        // AppendToEnvFile(reversePrimerArrayEnv, serviceName)
        AppendToEnvFile(readTypeVariable, serviceName);
        AppendToEnvFile(dataFormatVariable, serviceName);
        AppendToEnvFile(fileExtensionVariable, serviceName);
        AppendToEnvFile(oligosFileVariable, serviceName)
        return serviceName;
      }
    });
  // Save hard-coded inputs

  // Capture numeric input
  $(WorkFlowTag)
    .find("#" + serviceName)
    .find(".InlineNumericInput")
    .each(function () {
      if ($(this)[0].value !== "") {
        env_variable =
          $(this)
            .attr("id")
            .replace(/[ -=,]/g, "") +
          "=" +
          $(this).attr("id") +
          $(this)[0].value;
        console.log(env_variable);
        AppendToEnvFile(env_variable, serviceName);
      } else {
        env_variable =
          $(this)
            .attr("id")
            .replace(/[ -=,]/g, "") + "= ";
        console.log(env_variable);
        AppendToEnvFile(env_variable, serviceName);
      }
    });
  // Capture ON/OFF input
  $(WorkFlowTag)
    .find("#" + serviceName)
    .find(".onOff")
    .each(function () {
      if ($(this).is(":checked")) {
        env_variable =
          $(this)
            .attr("id")
            .replace(/[ -=,]/g, "") + "=ON";
        console.log(env_variable);
        AppendToEnvFile(env_variable, serviceName);
      } else {
        env_variable =
          $(this)
            .attr("id")
            .replace(/[ -=,]/g, "") + "=OFF";
        console.log(env_variable);
        AppendToEnvFile(env_variable, serviceName);
      }
    });
  console.log("All env variables written");
}

// Run Button
$("#runButton").click(async function () {
  // forwardPrimerArray = [];
  // reversePrimerArray = [];
  
  // $('#forwardPrimerChip > .chip').each(function (index, item) {
  //   forwardPrimerArray.push(item.innerText.replace('close','').replace(/(\r\n|\n|\r)/gm, ""))
  //   console.log(forwardPrimerArray);
  //   forwardPrimerArrayString = JSON.stringify(forwardPrimerArray)
  //   forwardPrimerArrayString = forwardPrimerArrayString.replace(/","/g, '" "')
  //   forwardPrimerArrayString = forwardPrimerArrayString.replace(/\[/g, '(')
  //   forwardPrimerArrayString = forwardPrimerArrayString.replace(/\]/g, ')')
  //   console.log(forwardPrimerArrayString)
  //   forwardPrimerArrayEnv = "fwdPrimers=" + forwardPrimerArrayString + "\n";
  //   console.log(forwardPrimerArrayEnv)

    
  // });
  // $('#reversePrimerChip > .chip').each(function (index, item) {
  //   reversePrimerArray.push(item.innerText.replace('close','').replace(/(\r\n|\n|\r)/gm, ""))
  //   console.log(reversePrimerArray);
  //   reversePrimerArrayString = JSON.stringify(reversePrimerArray)
  //   reversePrimerArrayString = reversePrimerArrayString.replace(/","/g, '" "')
  //   reversePrimerArrayString = reversePrimerArrayString.replace(/\[/g, '(')
  //   reversePrimerArrayString = reversePrimerArrayString.replace(/\]/g, ')')
  //   console.log(reversePrimerArrayString)
  //   reversePrimerArrayEnv = "revPrimers=" + reversePrimerArrayString + "\n";
  //   console.log(reversePrimerArrayEnv)
  // });

  Swal.fire({
    title: 'Do you want to save this configuration',
    showDenyButton: true,
    confirmButtonText: `Save`,
    denyButtonText: `Don't save`,
  }).then(async (result) => {
    console.log(result)
    /* Read more about isConfirmed, isDenied below */
    if (result.isConfirmed) {
      configSaveButton.click()
    }
  $("div.spanner").addClass("show");
  $("div.overlay").addClass("show");

  await clearEnvLine("workdir");
  defaultWorkDir = "workdir=/input \n";
  fs.appendFile(".env", defaultWorkDir, function (err) {
    if (err) {
    } else {
    }
  });

  workFlowSteps = $(".viewSwitch");
  if ($(".serviceCB:checked").length != workFlowSteps.length) {
    $("div.spanner").removeClass("show");
    $("div.overlay").removeClass("show");
    alert("A software must be checked for each step, remove unused steps");
    return false;
  }

  await processStepsInfo(workFlowSteps);
  console.log(
    "The whole workflow has completed: Show user stats and save configuration file"
  );

  $("div.spanner").removeClass("show");
  $("div.overlay").removeClass("show");
  })
});

$(document).on("click", "#DatabaseSelectButton", async function () {
  //Clear previos inputfolder from .env file
  clearEnvLine("userDatabase");
  // Open windows file dialog
  dialog
    .showOpenDialog({
      title: "Select the folder containing your sequnece files",
      properties: ["openFile", "showHiddenFiles"],
    })
    .then((result) => {
      console.log(result)
      userDatabaseFolder = path.dirname(result.filePaths[0])
      userDatabaseFile = path.basename(result.filePaths[0])
      inputPathEnv = "userDatabase=" + userDatabaseFolder + "\n";
      // Append folder path as a variable to .env file
      fs.appendFile(".env", inputPathEnv, function (err) {
        if (err) {
          console.log("append failed");
        } else {
          console.log("database file set as: " + userDatabaseFile);
        }
      });
    })
    .catch((err) => {
      console.log(err);
    });
});

$(document).on( "click", '#mothur-demultiplex', function() {
  $('.chips').find('input').restrict([8,'a','c', 'g', 't', 'r', 'y','s','w','k','m','b','d','h','v','n']);
  $('.chips').find('input').keyup(function() { 
    this.value = this.value.toLocaleUpperCase(); 
  }); 
});

$(document).on( "click", '#reorientReads.lever', function() {
  console.log('tere')
  $('.primerInput').fadeToggle()
})
