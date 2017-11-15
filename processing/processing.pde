import java.util.Arrays;
import processing.pdf.*;

String city; 
String[] cities;
PFont f;
int sizeX = 5000;
int sizeY = 5000;
boolean poster=false;
PShape cc_icon;
PShape provider_icon;
PImage okfn_logo;

public void settings() {
    if (args !=null && args.length > 1) {
        if ("poster".equals(args[1])) {
            okfn_logo = loadImage("okfn_logo.png");
            poster = true;
            sizeX = 9933;
            sizeY = 14043;
        } else {
            sizeX = Integer.parseInt(args[1]);
            sizeY = Integer.parseInt(args[1]);
        }
    }
    size(sizeX, sizeY);
}
  
void setup() {
  cc_icon = loadShape("CC-BY_icon.svg");
  provider_icon = loadShape(args[0] + ".svg");
  f = createFont("Lato", 48, true);
  
  cities = new String[1];
  
  if (args != null) {
    cities[0] = args[0]; 
  } else {
    println("Please specify a city/region");
    exit();
    System.exit(1);
  }
  
  beginRecord (PDF, "../output/" + join(cities, "-")  + ".pdf");
  smooth();
  noFill();
 
  stroke(255, 0, 0);
  strokeWeight(1);
  background(#000000);

  translate(50, 50);
  pushMatrix();   
    loadLines();
    drawRoute("7", #f781bf); // funicular
    drawRoute("6", #a65628); // gondola
    drawRoute("5", #ffff33); // cable car
    drawRoute("4", #ff7f00); // ferry
    drawRoute("3", #e41a1c); // bus
    drawRoute("2", #718792); // rail, inter-city
    drawRoute("1", #4daf4a); // subway, metro
    drawRoute("0", #1976d2); // tram
  popMatrix();
  
  if (poster) {
    textFont(f,88);
    fill(120);
    float provider_h = 564.0;
    float provider_w = provider_icon.width*provider_h/provider_icon.height;
    shape(provider_icon, 200, sizeY-provider_h-190, provider_w, provider_h);

    String[] lines = loadStrings("../texts/" + cities[0] + ".txt");
    text(join(lines, "\n"), 380 + provider_w, sizeY-600);
    
    textAlign(RIGHT);
    text("\n\nCreated by Roman Prokofyev\nLicense Creative Commons Attribution 4.0 Unported", sizeX - 1500, sizeY-600);
    shape(cc_icon, sizeX-690-700, sizeY-246-180, 690, 246);
    image(okfn_logo, sizeX-350-280, sizeY-380-150, 370, 410);
  }
  endRecord();
 exit();
}

String lines[];
float[] maxmin = new float[2];
void loadLines() { 
  maxmin[0] = 0.0f; 
    
  for (int i = 0; i < cities.length; i++) {
    String[] maxmin_i = loadStrings("../output/" + cities[i] + "/maxmin.lines");
    if (float(maxmin_i[0]) > maxmin[0])
      maxmin[0] = float(maxmin_i[0]);
  } 
}

void drawRoute(String type, color col) {
  for (int i = 0; i < cities.length; i++) {
    BufferedReader reader;
    String lineS;
    reader = createReader("../output/" + cities[i] + "/data.lines");
    while(true) {
      try {
        lineS = reader.readLine();
      } catch (IOException e) {
        e.printStackTrace();
        lineS = null;
      }
      if (lineS==null) {
         break;
      }
      String[] line = lineS.split("\t");
      String trips =   line[0];
      String[] route_types = line[1].split(",");

      String[] points = line[2].split(",");

      float f = 1.7f;

      float strkWeight = log(float(trips)  * f ) * 3;
      if (strkWeight < 0) strkWeight = 1.0f * f;
      strokeWeight(strkWeight);
      strokeCap(SQUARE);

      float alph = 100 * (float(trips)/maxmin[0]);
      if (alph < 20.0f) {
        alph = 20.0f;
      }
      //alph = 15.0f + (log(float(trips)) * 4.0f);
      //alph = 3.0f + (log(float(trips)) * 0.7f);

      stroke(col, alph);

      if (!Arrays.asList(route_types).contains(type) || route_types.length > 1)
        continue;

      beginShape();
      for (int n = 0; n < points.length; n++) {
        if (points[n] == "" ) continue;

        String[] coords = new String[2];
        coords = points[n].split(" ");

        if (coords.length != 2) continue;

        vertex(float(coords[0]), float(coords[1]));
      }
      endShape();
    } 
  }
}

void draw() {}