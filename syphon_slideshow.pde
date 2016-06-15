import controlP5.*;
ControlP5 cp5;
import codeanticode.syphon.*;
SyphonServer server;

PGraphics canvas;

ArrayList<File> filesList = new ArrayList<File>();
String folderSelection;

// timers
long lastTimeChecked = 0;

// controls
int photoChangeInterval = 2;
boolean resizing = true;

int currentPhoto = 0;
boolean doneLoading = false;

void settings() {
  size(800, 400, P3D);
  PJOGL.profile=1;
}

void setup() {

  canvas = createGraphics(1280, 720, P3D);

  canvas.beginDraw();
  canvas.imageMode(CENTER);
  canvas.endDraw();

  // set up syphon
  server = new SyphonServer(this, "photo slideshow");

  // set up GUI controls
  cp5 = new ControlP5(this);
  cp5.addSlider("photoChangeInterval")
    .setPosition(10, 10)
    .setSize(200, 30)
    .setRange(1, 20)
    .setNumberOfTickMarks(20)
    .setLabel("Slide Duration")
    ;
  cp5.addToggle("resizing")
    .setPosition(10, 60)
    .setSize(30, 30)
    .setLabel("Enable auto image resizing")
    ;

  selectFolder("Select a folder to process:", "folderSelected");
}

void draw() {

  // has enough time passed to advance photo?
  // only if we've already loaded photos in
  if (millis() > lastTimeChecked + (photoChangeInterval * 1000) && doneLoading) {

    // are there photos in the chosen folder?
    if (filesList.size() >= 1) {

      // change the photo
      currentPhoto++;

      // did we reach the end?
      if (currentPhoto >= filesList.size())
        currentPhoto = 0;

      // grab path to image
      File f = filesList.get(currentPhoto);
      PImage currentImg = loadImage(f.getAbsolutePath());

      // resize?
      if (resizing) {
        if (currentImg.width >= currentImg.height) {
          // hot dog
          currentImg.resize(canvas.width, 0);

          // is image still too tall?
          if (currentImg.height > canvas.height) {
            currentImg.resize(0, canvas.height);
          }
        }

        if (currentImg.width < currentImg.height) {
          // hamburger
          currentImg.resize(0, canvas.height);

          // is image still too wide?
          if (currentImg.width > canvas.width) {
            currentImg.resize(canvas.width, 0);
          }
        }
      }

      // do it
      background(0);
      canvas.beginDraw();
      canvas.clear();
      canvas.imageMode(CENTER);
      canvas.image(currentImg, canvas.width/2, canvas.height/2);
      canvas.endDraw();

      image(canvas, 0, 0, width, height);

      // out via syphon
      server.sendImage(canvas);
    }
    
    // refresh folder
    refreshFolder();
    lastTimeChecked = millis();
  }
}

void folderSelected(File selection) {
  if (selection == null) {
    println("you somehow selected something that wasn't a folder");
  } else {
    println("you selected " + selection.getAbsolutePath());

    // global string to keep track of our active folder
    folderSelection = selection.getAbsolutePath();

    // call refresh function to get list of files in said folder
    refreshFolder();
  }

  printArray(filesList);
  doneLoading = true;
}

void refreshFolder() {
  // first clear out the old list
  filesList.clear();

  // load files into memory if they're images
  File file = new File(folderSelection);
  File[] files = file.listFiles();
  //printArray(files);
  for (int i = 0; i < files.length; i++) {

    if (files[i].getPath().endsWith("jpg") || files[i].getPath().endsWith("png") || files[i].getPath().endsWith("jpeg") || files[i].getPath().endsWith("gif"))
      filesList.add(files[i]);
  }
}