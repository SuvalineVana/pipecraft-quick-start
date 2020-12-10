// Modules to control application life and create native browser window
const { app, BrowserWindow, ipcMain } = require('electron')
const os = require("os");
const pty = require("node-pty")
const path = require('path')

var shell = os.platform() === "win32" ? "powershell.exe" : "bash";
 
// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow

function createWindow() {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 720,
    frame: false,
    resizable: true,
    // maxWidth: 1280,
    maximizable: false,
    // fullscreenable: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true
    }
  })

  // and load the index.html of the app.
  mainWindow.loadFile('index.html')

  // Open the DevTools.
  // mainWindow.webContents.openDevTools()

  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null
  });

  var ptyProcess = pty.spawn(shell, [], {
    name: "xterm-color",
    cols: 90,
    rows: 20,
    cwd: process.env.HOME,
    env: process.env
  });

  ptyProcess.on("data", function(data) {
    mainWindow.webContents.send("terminal.incData", data);
  });
  // ptyProcess.write('clear\r')
  // ptyProcess.write('echo "Setting up the terminal"\r');
  // ptyProcess.write('clear\r');

  ipcMain.on("terminal.toTerm", function(event, data){
    ptyProcess.write(data);
  });

  ipcMain.on("clearTerminal", function(){
    ptyProcess.write('ls\r');
  });

  ipcMain.on("startContainer", function(event, data){
    ptyProcess.write(data);
  });

  ipcMain.on("exitContainer", function(){
    ptyProcess.write('exit\r');
  });
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow)

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On macOS it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') app.quit()
})

app.on('activate', function () {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) createWindow()
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.