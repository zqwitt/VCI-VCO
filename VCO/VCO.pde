import processing.pdf.*;


JSONArray colorValues;
boolean wall = false;
boolean loaded = false;
int size = 1;
int spacing =0;
String name;
int cW = 100;
int cH = 100;
void setup() {
  selectInput("Select the JSON file you wish to export as an image", "jsonConvert");
  if (wall) {
    size(100, 100);
  } else {
    size(100,100);
  }
  frame.setResizable(true);
  beginRecord(PDF, "birdman.pdf"); 
  colorMode(HSB, 360,360,360);
  
}

void jsonConvert(File selection) {

  if (selection ==null) {
    println("Window was closed! No file found");
    exit();
  } else {
    String fname = selection.getName();
    name  = fname.substring(0,fname.length()-5);
    
    String fpath = selection.getAbsolutePath();
    colorValues = loadJSONArray(fpath);

    for (int i =1; i<colorValues.size (); i+=colorValues.size()/height) {
      JSONObject colors = colorValues.getJSONObject(i);
      int hue = colors.getInt("hue");
      int sat = colors.getInt("saturation");
      int bri = colors.getInt("brightness");
      stroke(hue, sat, bri);
      
      line(0, i/(colorValues.size()/height), width, i/(colorValues.size()/height));
      if (i+1>colorValues.size()) {
        noLoop();
        loaded = true;
      }
    }
    endRecord();
  }

}

void draw() {
    if (loaded) {
    noLoop();
    
  }
   
      saveFrame(name+"-"+cW+"-"+cH+".png");
}