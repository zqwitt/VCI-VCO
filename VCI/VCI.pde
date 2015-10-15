/* //<>// //<>// //<>//
This program takes an .mov video file and exports 
 the most common colour of each frame to a .json file.
 The program must run for the duration of the film
 */

import processing.video.*;
//the video file that is being processed
Movie Video;
JSONArray colors;
int framecounter=1;
//integers that carry the average hue, saturation, and brightness
int h; 
int s; 
int b; 
//Lists that carry the total color of the cropped video file
IntList huList; 
IntList saList;
IntList brList;
float time; //the time past in the video
int maxNotBar=0; //the holder for the amount of pixels that rest in the black bars
//the cropped image
PImage VideoCropp;
//the movie name
String movieName = "";
//if the movie has a weird aspect ratio, such as 4:3 set this boolean to true;
boolean fullscreen = true;
boolean boxxed = false;
boolean pause = false;
boolean loading = true;
boolean noview = false;
void setup() {
  // a json file is created
  colors = new JSONArray();
  //fullScreen();
  size(1280,720, FX2D);
  //surface.setResizable(true);
  colorMode(HSB, 360); //set color to HSB, all values equal 360 for ease
  imageMode(CENTER); //image mode to center to allow for easy framing
  rectMode(CENTER); //rect mode to center to allow for easy framing
  frameRate(12); //framerate is decreased to not hurt the CPU (as much)...
  //lists are initialize
  huList = new IntList();
  saList = new IntList();
  brList = new IntList();
  thread("loadMovie");
}

void loadMovie() {
  selectInput("CHOOSE THE MOVIE YOU WOULD LIKE TO EXPORT", "fileSelect");
}

void fileSelect(File selection) {

  if (selection == null) {
    println("----NO FILE SELECT----");
  } else {
    Video = new Movie(this, selection.getAbsolutePath()); //load in the desired video


    Video.play(); //loop the video
    Video.speed(1);
    loading=false;
    movieName = selection.getName();
    int pos = movieName.indexOf(".");

    if (pos>0) {
      movieName = movieName.substring(0, pos);
    }
    movieName = movieName.toLowerCase();
  }
}


void draw() {
  if (loading==false) {
    if (pause==false) {
      if (Video.width>0 || Video.height>0) {
        //Lists are cleared each frame
        huList.clear();
        saList.clear();
        brList.clear();
 
        //video frame is cropped
        //surface.setSize(Video.width+100, Video.height+100);
        if (!fullscreen) {
          VideoCropp = VideoCrop(Video);
        } else {
          VideoCropp = Video;
        }
        //get the most common color of the frame of the cropped video
        colorAverage(VideoCropp);
        //set background to most common color
        background(h, s, b);
        //display the film
        image(VideoCropp, width/2, height/2, Video.width-100, Video.height-100);
        //exports the files when the video is over
        //interactive bar for easy jumping of time
        lineMarker();
        export();
      }
    } else {
      Video.pause();
    }
  }
}



// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}
//this function exports the color of the frame every time draw is called
//once the time of the video is half of a second before the end
// of the video the exported data is flushed out of memory
//and the program is closed
void export() {
  JSONObject Frame = new JSONObject();
  Frame.setInt("hue", h);
  Frame.setInt("saturation", s);
  Frame.setInt("brightness", b);
  colors.setJSONObject(framecounter, Frame);
  framecounter++;
  if (Video.time() >= (Video.duration()-0.5)) {
    saveJSONArray(colors, "data/json/"+movieName+".json");
    exit();
  }
}
//this function appends values to the color lists 
//and then adds them to a sum total and averages the values
//then the global color values are equated
void colorAverage(PImage mov) {
  int movPixels = mov.pixels.length;
  float hT =0;
  float sT =0;
  float bT =0;
  //extracts hue, sat, and bri from frame
  for (int i =0; i<movPixels; i++) {
    int pixel = mov.pixels[i];
    int hue = int(hue(pixel));
    int saturation = int(saturation(pixel));
    int brightness = int(brightness(pixel));
    huList.append(hue);
    saList.append(saturation);
    brList.append(brightness);
    //sums the total of frames
    hT += huList.get(int(i));
    sT += saList.get(int(i));
    bT += brList.get(int(i));
  }
  float smean = sT/movPixels;
  float bmean = bT/movPixels;
  //most common hue
  //average saturation and brightness
  h = int(mode(huList));
  s = int(((mode(saList))+smean)/2);
  b = int(((mode(brList))+bmean)/2);
}

//this function creates an interactive bar that allows for skipping of time, and debugging
void lineMarker() {
  time = map(mouseX, ((width/2)-((width-10)/2)), 
    ((width/2)+((width-10)/2)), 0, Video.duration());
  float barW; //the width of the bar
  float md = Video.duration(); 
  float mt = Video.time(); 
  stroke(0, 0, 260); 
  strokeWeight(1);
  fill(0, 0, 0, 0); 
  rectMode(CENTER);
  rect(width/2, height-10, width-10, 5); 
  float lineLength=map(mt, 0, md, 0, width-10); 
  rectMode(CORNER); 
  fill(0, 0, 360); 
  rect(5, height-12.5, lineLength, 5); 
  rectMode(CENTER);
}
//checks to see if the mouse is released while in the interactive line
//then jumps to desireed time
void mouseReleased() {
  if (mouseX >=((width/2)-((width-10)/2)) && mouseX <= ((width/2)+((width-10)/2))&& mouseY >=(height-10-5) && mouseY <=(height-10+5)) {
    Video.jump(time);
  }
}
//equates the most common value out of a list of integer values
int mode(IntList list) {
  int[] modeMap = new int [list.size()];
  int maxEl = list.get(0);
  int maxCount = 1;
  for ( int i =0; i <list.size (); i++) {
    int el = list.get(i); 
    if (modeMap[el] ==0) {
      modeMap[el] =1;
    } else {
      modeMap[el]++;
    }
    if (modeMap[el] >maxCount) {
      maxEl = el;
      maxCount = modeMap[el];
    }
  }
  return maxEl;
}
//crops the video and returns a pimage of the frame given
PImage VideoCrop(PImage m) {

  if (boxxed) {
    int originx = 0;
    int originy = 0;
    boolean getLoc =false;
    int threshold = 24;
    for (int x=0; x<m.width &&!getLoc; x++) {
      for (int y=0; y<m.height &&!getLoc; y++) {
        int loc = x+m.width*y;
        if (brightness(m.pixels[loc])>threshold) {
          getLoc=true;
          originx =x;
        }
      }
    }
    getLoc =false;
    for (int y=0; y<m.height &&!getLoc; y++) {
      for (int x=0; x<m.width &&!getLoc; x++) {
        int loc = x+m.width*y;
        if (brightness(m.pixels[loc])>threshold) {
          getLoc=true;
          originy =y;
        }
      }
    }
    int xC=abs(originx);
    int yC=abs(originy);
    int wC=abs(m.width-originx*2);
    int hC=abs(m.height-originy*2);
    PImage videoCropped = m.get(xC, yC, wC, hC); 
    return videoCropped;
  } else {
    int notBar=0;
    for (int i =0; i<m.pixels.length; i++) {
      if (brightness(m.pixels[i])>0) {
        notBar++;
      }
    }
    if (maxNotBar<notBar) {
      maxNotBar=notBar;
    }
    int blackBarHeight = int(((m.pixels.length-maxNotBar)/(m.width+0.1))/2); 
    PImage videoCropped = m.get(0, blackBarHeight, m.width, m.height-blackBarHeight*2);
    return videoCropped;
  }
}
void keyPressed() {

  if (key==' ') {
    if (pause==false) {
      pause=true;
    } else {
      pause=false;
    }
  }

  if (key=='v') {
    Video.volume(1);
  }
}