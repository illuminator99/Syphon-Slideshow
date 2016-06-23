/*
  written in a jiff by grayson earle of the illuminator
  free to use for creative/activist purposes
  www.graysonearle.com
  www.github.com/prismspecs
*/

import controlP5.*;
ControlP5 cp5;
import codeanticode.syphon.*;
SyphonServer server;
import processing.video.*;
Movie movie;

PGraphics canvas;
PImage currentFrame;

ArrayList<File> filesList = new ArrayList<File>();
String folderSelection;

// timers
long lastTimeChecked = 0;

// controls
int photoChangeInterval = 2;
boolean resizing = true;
boolean movieResizing = true;

int currentPhoto = 0;
boolean doneLoading = false;
boolean isMovie = false;

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
    .setSize(400, 30)
    .setRange(1, 40)
    .setNumberOfTickMarks(40)
    .setLabel("Slide Duration")
    ;
  cp5.addToggle("resizing")
    .setPosition(10, 60)
    .setSize(30, 30)
    .setLabel("Enable auto image resizing")
    ;
  cp5.addToggle("movieResizing")
    .setPosition(10, 110)
    .setSize(30, 30)
    .setLabel("Enable auto movie resizing (not perfect)")
    ;

  selectFolder("Select a folder to process:", "folderSelected");
}

void draw() {

  // has enough time passed to advance photo?
  // only if we've already loaded photos in
  if (millis() > lastTimeChecked + (photoChangeInterval * 1000) && doneLoading && !isMovie) {

    // are there photos in the chosen folder?
    if (filesList.size() >= 1) {

      // grab path to image/movie
      File f = filesList.get(currentPhoto);

      println(f.getAbsolutePath());

      // is it an image or a movie?
      if (f.getPath().endsWith("mov") || f.getPath().endsWith("MOV") || f.getPath().endsWith("mp4")) {

        // --- MOVIE ---
        isMovie = true;
        movie = new Movie(this, f.getAbsolutePath());
        movie.play();

        //println("movie loaded");

        // store each frame so we can resize like image
        currentFrame = new PImage(movie.width, movie.height);
      } else {

        // --- IMAGE ---

        isMovie = false;
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

        // draw image to screen and canvas/syphon context
        background(0);
        canvas.beginDraw();
        canvas.clear();
        canvas.imageMode(CENTER);
        canvas.image(currentImg, canvas.width/2, canvas.height/2);
        canvas.endDraw();
      }

      image(canvas, 0, 0, width, height);

      // out via syphon
      server.sendImage(canvas);

      // change the photo
      currentPhoto++;

      // did we reach the end?
      if (currentPhoto >= filesList.size())
        currentPhoto = 0;
    }

    // refresh folder
    refreshFolder();
    lastTimeChecked = millis();
  }

  // movie has different logic--play until done!
  if (isMovie && doneLoading) {

    currentFrame = movie.get();

    background(0);
    canvas.beginDraw();
    canvas.clear();
    canvas.imageMode(CENTER);
    if (movieResizing)
      canvas.image(currentFrame, canvas.width/2, canvas.height/2, canvas.width, canvas.height);
    else
      canvas.image(currentFrame, canvas.width/2, canvas.height/2);
    canvas.endDraw();
    image(canvas, 0, 0, width, height);

    // out via syphon
    server.sendImage(canvas);

    // is it essentially at the end of the movie?
    // need to do .99 otherwise it hangs
    if (movie.time() >= movie.duration() * .99) {
      isMovie = false;
    }
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

    if (files[i].getPath().endsWith("jpg") || files[i].getPath().endsWith("JPG") || files[i].getPath().endsWith("png") || files[i].getPath().endsWith("PNG") || files[i].getPath().endsWith("jpeg") || files[i].getPath().endsWith("mov") || files[i].getPath().endsWith("MOV") || files[i].getPath().endsWith("mp4"))
      filesList.add(files[i]);
  }
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}