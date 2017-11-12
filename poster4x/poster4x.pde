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

    cities = new String[4];
    cities = new String [] {"amsterdam", "rotterdam", "hague", "utrecht"};

    if (args != null) {
        cities[0] = args[0];
        cities[1] = args[1];
        cities[2] = args[2];
        cities[3] = args[3];
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

    if (poster) {
        pushMatrix();
        // 0,0 is top left
        translate(0, 1600);
    }
    translate(500, 500);
    pushMatrix();
        loadLines();
        drawRoute("7", #f781bf); // funicular
        drawRoute("6", #a65628); // gondola
        drawRoute("5", #ffff33); // cable car
        drawRoute("4", #ff7f00); // ferry
        drawRoute("3", #e41a1c); // bus
        drawRoute("2", #984ea3); // rail, inter-city
        drawRoute("1", #4daf4a); // subway, metro
        drawRoute("0", #1976d2); // tram
    popMatrix();

    if (poster) {
        popMatrix();
        textFont(f,88);
        fill(120);
    //float scale = 564/provider_icon.height;
    //provider_icon.scale(scale);
    //shape(provider_icon, 200, sizeY-564-190);
    //text("\n\nVisuzalization of public transport routes based on the GTFS feed by the Vilnius Transport\n" +
    //"Source code and further information are available at github.com/dragoon/gtfs-visualizations", 350 + provider_icon.width*scale, sizeY-620);

    //textAlign(RIGHT);
    //text("\n\nCreated by Roman Prokofyev\nLicense Creative Commons Attribution 4.0 Unported", sizeX - 1500, sizeY-600);
    //shape(cc_icon, sizeX-690-700, sizeY-246-180, 690, 246);
    //image(okfn_logo, sizeX-350-280, sizeY-380-150, 370, 410);
    }
    endRecord();

    save("../output/" + join(cities, "-") + ".png");
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
      if(i==1){
        pushMatrix();
        translate(4933,0);
      }
        if(i==2){
        pushMatrix();
        translate(0, 5343);
        }
        if(i==3){
        pushMatrix();
        translate(4933, 5343);
        }
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
     if (i>0) {
        popMatrix();
     }
  }
}

void draw() {}