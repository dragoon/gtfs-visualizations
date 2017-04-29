import java.util.Arrays;
import processing.pdf.*;

String city; 
String[] cities;

public void settings() {
  if (args !=null && args.length > 1) {
    size(Integer.parseInt(args[1]), Integer.parseInt(args[1]));
  } else {
    size(5100, 5100);
  }
}
  
void setup() {
  /*
  cities =  new String[2];
  cities[0] = "los-angeles";
  cities[1] = "los-angeles-metro";
 
  //"los-angeles";
  //"washington-dc";
  //"san-diego";
  //"manhattan";
  //"miami";
  //"san-francisco";                  
  //"madrid";

  cities[0] = "madrid";
  cities[0] = "washington-dc";
  */
  
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
  background(#191919);
  
  translate(50, 50);
  pushMatrix();   
    loadLines();
    drawRoute("7", #f781bf); // funicular
    drawRoute("6", #a65628); // gondola
    drawRoute("5", #ffff33); // cable car
    drawRoute("4", #ff7f00); // ferry
    drawRoute("3", #e41a1c); // bus
    drawRoute("2", #984ea3); // rail, inter-city
    drawRoute("1", #4daf4a); // subway, metro
    drawRoute("0", #0000ff); // tram
  popMatrix();
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
  
      float f = 0.7f;
      
      float strkWeight = log(float(trips)  * f );
      if (strkWeight < 0) strkWeight = 1.0f * f;
      strokeWeight(strkWeight);
        
      float alph = 1.0 + (maxmin[0] / float(trips));
      alph = 15.0f + (log(float(trips)) * 4.0f);
      alph = 3.0f + (log(float(trips)) * 0.7f);
      
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
