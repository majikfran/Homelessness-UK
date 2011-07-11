import geomerative.*;
import org.apache.batik.svggen.font.table.*;
import org.apache.batik.svggen.font.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

RShape UK;
PGraphics buffer;
PImage img;
boolean bufferRendered = false;
File data;
Scanner reader;
String aLine;
String aMatch;
int valueToGet = 12; //12 for number, 13 for per 1000 households
Set<String> namesToExclude;

sideFactView view;
PFont font; 
PFont font2; 


List<String> headers;
List<ArrayList<String>> values;

color [] colorScale = {
  //color( 255, 245, 240), 
  color( 254, 224, 210), 
  color( 252, 187, 161), 
  color( 252, 146, 114), 
  color( 251, 106, 74), 
  color( 239, 59, 44), 
  color( 203, 24, 29), 
  color( 165, 15, 21), 
  color( 103, 0, 13)
};


float maxValHomeless;
float minValHomeless;

Pattern csvR;

void setup()
{
  size(1024, 768);
  background(245);
  smooth();
  namesToExclude = new HashSet<String>();
  //namesToExclude.add("england");
  //namesToExclude.add("london");
  String [] lines = loadStrings("data.csv");
  /*data = new File(dataPath("Homelessness Q1 2011 edited.csv"));
   try {
   reader = new Scanner(data);
   }
   catch(FileNotFoundException e) {
   println("File Not Found");
   }*/

  font = loadFont("boldfont-24.vlw");
  font2 = loadFont("normalfont-20.vlw");
  textFont(font, 24);

  headers = new ArrayList<String>();
  values = new ArrayList<ArrayList<String>>();
  ArrayList<String> temp = new ArrayList<String>();

  aLine = lines[0];//reader.nextLine();

  Pattern csvR = Pattern.compile("\"([^\"]+?)\",?|([^,]+),?|,");
  Matcher m = csvR.matcher(aLine);

  while (m.find ()) {
    aMatch = m.group();
    headers.add(aMatch);
  }

  //while (reader.hasNextLine ())
  for (int i =1 ; i<lines.length;i++)
  {
    temp = new ArrayList<String>();
    aLine = lines[i];//reader.nextLine();
    m = csvR.matcher(aLine);
    while (m.find ()) {
      aMatch = m.group();
      if (aMatch.endsWith(",")) {
        aMatch = aMatch.substring(0, aMatch.length() - 1);
      }
      if (aMatch.startsWith("\"")) {
        aMatch = aMatch.substring(1, aMatch.length() - 1);
      }
      if (aMatch.length() == 0)
        aMatch = null;

      temp.add(aMatch);
    }

    values.add(temp);
  }
  //println("Max value should be " + values.get(0).get(valueToGet));
  maxValHomeless = Float.MIN_VALUE;
  for (int i = 0; i < values.size(); i++)
  {
    if (isUpperCase(values.get(i).get(3))) {
      namesToExclude.add(values.get(i).get(3));
      println(values.get(i).get(3));
    }
    if (Float.valueOf(values.get(i).get(valueToGet)) > maxValHomeless && !namesToExclude.contains(values.get(i).get(3)))
      maxValHomeless = Float.valueOf(values.get(i).get(valueToGet));
  }

  minValHomeless = maxValHomeless;
  for (int i = 0; i < values.size(); i++)
  {
    if (Float.valueOf(values.get(i).get(valueToGet)) < minValHomeless)
      minValHomeless = Float.valueOf(values.get(i).get(valueToGet));
  }

  println("Max and min are " + maxValHomeless + " and " + minValHomeless);

  buffer = createGraphics(width, height, JAVA2D);
  RG.init(this);

  RG.ignoreStyles();
  UK = RG.loadShape("UKMap.svg");
  UK.scale(0.5);

  UK.translate(400, 0);

  view = new sideFactView(color(62, 140, 100), 255, 300, 10, true, "ENGLAND");
}

void draw()
{
  PGraphics originalG = null;
  background(245);
  if (!bufferRendered) {
    //make changes to render to buffer
    originalG = g;
    g = buffer;
    g.beginDraw();
    g.smooth();
    g.background(245);
    g.stroke(245);
    g.strokeWeight(1);
    //UK.draw();
    int count = 0;
    float aFill = 0;
    for (int i = 0; i < UK.countChildren(); i++)
    {
      aFill=0;
      //fill(0, 100, 50);
      for (int e = 0; e < values.size(); e++)
      {
        //println(UK.children[i].name.toLowerCase() + " = " + values.get(e).get(3).toLowerCase());

        if (UK.children[i].name.toLowerCase().equals(values.get(e).get(3).toLowerCase()))
        {
          aFill = Float.valueOf(values.get(e).get(valueToGet));
          //fill(map((int)aFill, 0, (int)maxValHomeless, 0, 255), 240 - map((int)aFill, 0, (int)maxValHomeless / 20, 0, 255), 240 - map((int)aFill, 0, (int)maxValHomeless / 20, 0, 255) );
          color a= mappedLogColor(aFill, 0.0, (maxValHomeless));
          fill(a);
          //println(red(a) + " "+ green(a) + " " + blue(a) + " " +alpha(a));
          count++;
        }
      }

      UK.children[i].draw();
    }
    println(count);
    g.endDraw();
    img = buffer.get(0, 0, width, height);
    bufferRendered = true;
    g = originalG;
  }
  image(img, 0, 0);
  noStroke();
  for (int i = 0; i < UK.countChildren(); i++)
  {
    RPoint p = new RPoint(mouseX, mouseY);
    if (UK.children[i].contains(p))
    {
      pushMatrix();
      fill(245);
      stroke(245);
      strokeWeight(1);
      UK.children[i].draw();
      //noStroke();
      stroke(245);
      fill(255, 0, 0);
      scale(1.005);
      UK.children[i].draw();
      println(UK.children[i].name);
      popMatrix();
      if (mousePressed)
      {
        view.updateData(UK.children[i].name); 
        if (view.isOut())
        {
          view.in();
          view.grow();
        }
        else
          view.grow();
      }
    }
  }
  view.update();
}

/*void mouseClicked()
 {
 if (view.isOut())
 view.shrink();
 else
 view.grow();
 }*/

class factView
{
  Integrator moveX;
  Integrator moveY;
  boolean isOut;
  color aColor;
  int oppacity;

  factView(color col, int oppac)
  {
    isOut = false;
    aColor = col;
    oppacity = oppac;
  }

  boolean isOut()
  {
    return isOut;
  }
}

class sideFactView extends factView
{
  float width, height;
  float maxWidth, minWidth;
  boolean side;
  String place;
  int alphaFade;

  sideFactView(color col, int oppac, float maxW, float minW, boolean aSide, String aPlace)
  {
    super(col, oppac);
    super.moveX = new Integrator(minW);
    maxWidth = maxW;
    minWidth = minW;
    width = minW;
    height = screenHeight;
    side = aSide;
    place = aPlace;
  }

  void grow()
  {
    moveX.target(maxWidth);
    this.isOut = true;
  }

  void shrink()
  {
    moveX.target(minWidth);
    this.isOut = false;
  }

  void in()
  {
    //width = minWidth;
    moveX.value = minWidth;
    this.isOut = false;
    alphaFade = 200;
  }

  void out()
  {
    //width = maxWidth;
    moveX.value = minWidth;
    this.isOut = true;
  }

  void updateData(String aPlace)
  {
    place = aPlace;
  }

  void update()
  {
    if(this.isOut())
    {
      noStroke();
      fill(aColor, alphaFade);
      rect(0, 0, maxWidth, height);

    }
    moveX.update();
    width = moveX.value;

    noStroke();
    fill(aColor, oppacity);
    rect(0, 0, width, height);

    textAlign(CENTER);
    fill(245);
    textFont(font, 24);
    text(place, maxWidth / 2 - (maxWidth - width), 40);

    /*for(int i = 0; i < headers.size(); i++)
    {
      textAlign(LEFT);
      textFont(font2, 20);
      text(headers.get(i), 20 - (maxWidth - width), (i*20) + 60);
    }*/
    textAlign(LEFT);
    textFont(font2, 20);
    text("Total Number of Homeless People", 20 - (maxWidth - width), 80);
    
    for(int i = 0; i < values.size(); i++)
    {
      if(values.get(i).get(3).equals(place))
      {
        int noWholeBlocks = (int)((Float.valueOf(values.get(i).get(12))) / 20);
        float noBlocks = noWholeBlocks + (Float.valueOf(values.get(i).get(12)) - (20 * noWholeBlocks)) / 20.0;
        
        int displacement = 0;
        for(int e = 0; e < noBlocks - 1; e ++)
        {
          
          if(e % 10 == 0)
            displacement = 0;
          else
            displacement++;
            
          fill(255);
          rect(displacement * 25 + (20 - (maxWidth - width)), ((e / 10) * 25) + 100, 20, 20);
        }
        text(values.get(i).get(12), 20 - (maxWidth - width), 100);
      }
    }
    
    
    if(this.width < maxWidth)
    {
      alphaFade-= 10;
    }
  }
}

color mappedColor(float a, float vmin, float vmax) {
  //println("Mapping " + a + " from " + vmin +" to " + vmax);  
  return colorScale[int(map(a, vmin, vmax, 0, colorScale.length-1))];
}

color mappedLogColor(float a, float vmin, float vmax) {
  //println("Mapping " + a + " from " + vmin +" to " + vmax);  
  return colorScale[int(map(log(a+1), log(vmin+1), log(vmax+1), 0, colorScale.length-1))];
}

boolean isUpperCase(String a) {
  return a.equals(a.toUpperCase());
}

