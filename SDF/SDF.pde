// Written by Anton Roy (AntonMakesGames)
import processing.svg.*;

String exportFileName = "Exports/sdfRecording";

GravityBody[] gravityBodies;
Body[] bodies;
int nbBodies = 300;
final float inkscapeFactor = 3.779528;

final float sceneSize = 792;
ArrayList<PVector>[] trajectories;
Parameters savedParam, currentParam;
float drag = 1.;
float noiseRange = .5;
float noiseZoom = .15;
PVector baseVelocityRange = new PVector(1, 30);
float mainMass = 2000;

PVector initialSpread = new PVector(200, 300);

float sdfPerturbation = .3;

boolean isRecording = false;

PVector centerOfMass;

SVGFont font;
String fontName = "../Font/HersheySans1.svg";

String counterSaveFileName = "../Counter/CounterSave";

String fieldName = "Circle.jpg";
float fieldFactor = -40.;
PImage sdf;
Vec4[] vecSdf;

enum States
{UpdatingBodies, PreparingPainting}
States state;

void ApplyParam(Parameters param)
{
  spawnBodiesInCircle(param);
  //spawnBodiesInSideLine(param);
  //spawnBodiesInLine(param);
  
  state = States.UpdatingBodies;
  background(250);
}

void spawnBodiesInLine(Parameters param)
{
  float ax = (sin(param.Angle) * param.Len) / nbBodies;
  float ay = (cos(param.Angle) * param.Len) / nbBodies;
  float dx = param.BaseVelocity.x;
  float dy = param.BaseVelocity.y;

  for(int index = 0; index < nbBodies; ++index)
  {
    float fndex = (float)index;
    float rv = 1;//random(0,1);
    bodies[index] = new Body(param.StartPos.x + ax * fndex, param.StartPos.y + ay * fndex, dx * rv, dy * rv);
    trajectories[index] = new ArrayList<PVector>();
  }
}

void spawnBodiesInCircle(Parameters param)
{
  float cx = width / 2;
  float cy = height / 2;
  float radius = param.Len;
  
  float len2 = param.BaseVelocity.x * param.BaseVelocity.x + param.BaseVelocity.y * param.BaseVelocity.y;
  float len = sqrt(len2);
  boolean outward = false;
  float speedFactor = 1;
  if(outward)
  {
    speedFactor = -1;
  }

  speedFactor *= len / radius;

  for(int index = 0; index < nbBodies; ++index)
  {
    float f = (float)index / (float)nbBodies * 6.28318;
    float ax = cos(f);
    float ay = sin(f);
    float px = cx + ax * radius;
    float py = cy + ay * radius;
    bodies[index] = new Body(px, py, (cx - px) * speedFactor, (cy - py) * speedFactor);
    trajectories[index] = new ArrayList<PVector>();
  }
}

void spawnBodiesAcrossScreen(Parameters param)
{
  float ratio = (float)height / (float)width;
  int index = 0;
  int nbLine = 10;
  float hfSize = (float)height / nbLine / 2;
  int nbColumn = nbBodies / nbLine;
  for(int i = 0; i < nbColumn; ++i)
  {
    for(int j = 0; j < nbLine; ++j)
    {
      float x = i / (float)nbColumn * width + hfSize;
      float y = j / (float)nbLine * height + hfSize;
      index = j * nbColumn + i;
      bodies[index] = new Body(x, y, 0, 0);
      trajectories[index] = new ArrayList<PVector>();
    }
  }
}

void spawnBodiesInSideLine(Parameters param)
{
  float halfWidth = (float)width/2.0;
  float shrnk = .85;

  int halfBodies = nbBodies / 2;

  boolean mirror = true;
  int loopcount = mirror ? halfBodies : nbBodies;

  for(int index = 0; index < loopcount; ++index)
  {
    bodies[index] = new Body(index / (float)loopcount * (float)width * shrnk + halfWidth * (1 - shrnk), 0, 0, param.BaseVelocity.x);
    trajectories[index] = new ArrayList<PVector>();

    if(mirror)
    {
      bodies[index + halfBodies] = new Body(index / (float)loopcount * (float)width * shrnk + halfWidth * (1 - shrnk), height, 0, -param.BaseVelocity.x);
      trajectories[index + halfBodies] = new ArrayList<PVector>();
    }
  }
}

void setup() {
  size(548, 377);

  font = loadFontXML(fontName);

  sdf = loadImage(fieldName);
  sdf.loadPixels();

  gravityBodies = new GravityBody[1];
  gravityBodies[0] = new GravityBody(width/2f, height/2f, mainMass);
  bodies = new Body[nbBodies];
  trajectories = new ArrayList[nbBodies];
  Parameters param = new Parameters();
  param.Randomize();
  savedParam = param;
  currentParam = param;
  buildVecSdf();
  ApplyParam(param);
}

float time = 0;

void buildVecSdf()
{
  
  //image(sdf, 0, 0, 548, 377);
  float heightFactor = (float)sdf.height / (float)height;
  vecSdf = new Vec4[width * height];
  for(int x = 0; x < width; ++x)
  {
    for(int y = 0; y < height; ++y)
    {
      int rx =(int)( (float)x / width * sdf.width);
      int ry = (int)((float)y / height * sdf.height);
      color argb = sdf.pixels[rx + ry * sdf.width];
      
      int a = (argb >> 24) & 0xFF;
      int r = (argb >> 16) & 0xFF;  // Faster way of getting red(argb)
      int g = (argb >> 8) & 0xFF;   // Faster way of getting green(argb)
      int b = argb & 0xFF;          // Faster way of getting blue(argb)

      float fa = (float)a / 128f - 1f;
      float fr = (float)r / 256f;
      float fg = (float)g / 128f - 1f;
      float fb = (float)b / 128f - 1f;
      int screenIndex = y * width + x;
      vecSdf[screenIndex] = new Vec4(fa,fr,fg,fb);
    }
  }
}

void draw()
{
  stroke(0);
  if(state == States.UpdatingBodies)
  {
    float dt = .1;
    time += dt;
    
    for(int index = 0; index < nbBodies; ++index)
    {
      Body body = bodies[index];
      if(body.dead)
      {
        continue;
      }
      
      body.Update(dt, gravityBodies);
      line(body.px,body.py,body.x,body.y);
      trajectories[index].add(new PVector(body.px,body.py));
    }
    
    stroke(255,0,0);
    for(int index = 0; index < gravityBodies.length; ++index)
    {
      circle(gravityBodies[index].x,gravityBodies[index].y, 3);
    }
  }
  else if(state == States.PreparingPainting)
  {
    background(225);
    
    if(isRecording)
    {
      String counter = ToHex(GetCount(counterSaveFileName));
      String fileName = GetAvailableFileName(exportFileName + counter, "svg");
      println("Start recording " + fileName);
      beginRecord(SVG, fileName);
    }
    
    circleCorner();
    
    Vec4 screenRect = new Vec4(0, 0, width, height);
    Vec4 signatureRect = GetSignRect();

    for(int index = 0; index < nbBodies;++index)
    {
      int nbPoints = trajectories[index].size();
      PVector p1 = trajectories[index].get(0);
      for(int i = 1; i < nbPoints; ++i)
      {
        PVector p2 = trajectories[index].get(i);
        if(InsideRect(p1, screenRect) && InsideRect(p2, screenRect) && !InsideRect(p1, signatureRect) && ! InsideRect(p2, signatureRect))
        {
          line(p1.x, p1.y, p2.x, p2.y);
        }

        p1 = p2;
      }

      if(isRecording && index % 10 == 0)
      {
        println((float)index / (float)nbBodies * 100f);
      }
    }
    
    Sign();

    if(isRecording)
    { 
      endRecord();
      println("Stop recording");
      IncrementSavedCounter(counterSaveFileName);
      isRecording = false;
    }
  }
}

void circleCorner()
{
  circle(1, 1, 2);
  circle(width - 1, 1, 2);
  circle(width - 1, height - 1, 2);
  circle(1, height - 1, 2);
}

void keyPressed()
{
  if(key == 'r')
  {
    println("Randomize current param");
    currentParam.Randomize();
    ApplyParam(currentParam);
  }
  
  if(key == 'a')
  {
    println("Apply current param");
    ApplyParam(currentParam);
  }
  
  if(key == 's')
  {
    println("Saved current param");
    savedParam = new Parameters(currentParam);
  }
  
  if(key =='l')
  {
    println("load current param");
    currentParam = new Parameters(savedParam);
    ApplyParam(currentParam);
  }
  
  if(key == 'p')
  {
    if(state == States.UpdatingBodies)
    {
      state = States.PreparingPainting;
    }
    else if(state == States.PreparingPainting)
    {
      state = States.UpdatingBodies;
    }
  }
  
  if(state == States.PreparingPainting)
  {
    if(key == 'o' && !isRecording)
    {
      isRecording = true;
    }
    
    if(key == 'j')
    {
      this.SimplifyAlignment();
    }
  }
}

void SimplifyLines()
{
  
  for(int index = 0; index < nbBodies;++index)
    {
      int nbPoints = trajectories[index].size();
      
      int halfPoints = nbPoints / 2;
      for(int i = 0; i < halfPoints; ++i)
      {
        trajectories[index].remove(nbPoints - 1 - i * 2);
      }
    }
}

void SimplifyAlignment()
{
  for(int pIndex = 0; pIndex < nbBodies; ++pIndex)
  {
    ArrayList<PVector> trajectory = trajectories[pIndex];
    int nbPoints = trajectory.size();
    for(int index = nbPoints - 2; index > 1; --index)
    {
      PVector p0 = trajectory.get(index);
      PVector p1 = trajectory.get(index + 1);
      PVector p2 = trajectory.get(index - 1);
      PVector a = PVector.sub(p1, p0).normalize();
      PVector b = PVector.sub(p2, p0).normalize();
      float dot = a.dot(b);
      if(abs(dot) == 1)
      {
        trajectory.remove(index);
      }
    }
  }
}

String GetAvailableFileName(String desiredFileName, String extension)
{
  String ext = "." + extension;
  if(!DoFileExist(desiredFileName + ext))
  {
    return desiredFileName + ext;
  }

  int counter = 1;
  while(counter < 100)
  {
    String name = desiredFileName + "_" + nf(counter,2);
    counter++;
    if(!DoFileExist(name + ext))
    {
      return name + ext;
    }
  }

  return "";
}

boolean DoFileExist(String fileName)
{
  fileName = sketchPath() + "\\" + fileName;
  File f = new File(fileName);
  String filePath = f.getPath();
  boolean exist = f.isFile();
  println(filePath, exist);
  return f.isFile();
}

class GravityBody
{
  float x,y,w;
  GravityBody(float x,float y,float w)
  {
    this.x = x;
    this.y = y;
    this.w = w;
  }
}

int clamp(int x, int low, int high)
{
  if(x < low) x = low;
  if(x > high) x= high;
  return x;
}

boolean InsideRect(PVector p, Vec4 rect)
{
  return p.x >= rect.x && p. x < rect.x + rect. z && p.y >= rect.y && p.y < rect.y + rect. w;
}

PVector Clone(PVector o)
{
  return new PVector(o.x, o.y);
}

class Body
{
  float x,y,px,py;
  PVector speed;
  PVector recordedSpeed;
  boolean isInZone;
  boolean dead;
  Body(float x,float y,float dx,float dy)
  {
    this.x = x;
    this.y = y;
    this.speed = new PVector(dx, dy);
    this.px = x;
    this.py = y;
    this.isInZone = false;
    this.dead = false;
  }
  
  void Update(float dt, GravityBody[] gBodies)
  {
    this.px = this.x;
    this.py = this.y;
    
    int sdfIndex = clamp((int) this.x, 0, width - 1) + clamp((int) this.y,0, height - 1) * width;


    Vec4 sdf = vecSdf[sdfIndex];
    boolean inZone = sdf.y > 0;
    float zoneForce = sdf.y;
    //this.dx = sdf.z * fieldFactor;
    //this.dy = sdf.w * fieldFactor;
    
    float n = (noise(this.x * noiseZoom, this.y * noiseZoom, .01) * noiseRange * 2) - noiseRange;
    if(inZone != this.isInZone)
    {
      if(inZone)
      {
        this.recordedSpeed = this.speed;
      }
      else
      {
        this.speed = this.recordedSpeed;
      }
    }

    this.speed = this.speed.rotate(n * zoneForce);
    if(inZone)
    {
    }

    this.x += this.speed.x * dt;
    this.y += this.speed.y * dt;

    this.isInZone = inZone;

    if(noiseRange != 0)
    {
//      this.speed.x += (noise(this.x * noiseZoom, this.y * noiseZoom, 0) * noiseRange * 2) - noiseRange;
 //     this.speed.y += (noise(this.x * noiseZoom, this.y * noiseZoom, 1) * noiseRange * 2) - noiseRange;
    }

    if(drag != 1)
    {
      this.speed.x = (this.speed.x * dt) * drag;
      this.speed.y = (this.speed.y * dt) * drag;
    }
  }
}

class Vec4
{
  float x,y,z,w;
  Vec4(float x, float y, float z, float w)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }
}

class Parameters
{
  PVector StartPos;
  float Angle, Len;
  PVector BaseVelocity;
  float[] Velocities;
  
  Parameters()
  {
    this.StartPos = new PVector(0, 0);
    this.Angle = 0;
    this.Len = 0;
    this.BaseVelocity = new PVector(0, 0);
    this.Velocities = new float[nbBodies];
  }
  
  Parameters(Parameters other)
  {
    this.StartPos = Clone(other.StartPos);
    this.Angle = other.Angle;
    this.Len = other.Len;
    this.BaseVelocity = Clone(other.BaseVelocity);
    this.Velocities = new float[nbBodies];
    for(int index = 0; index < nbBodies; ++index)
    {
      this.Velocities[index] = other.Velocities[index];
    }
  }
  
  void RandomizeStartPos()
  {
    float margin = 100;
    float lx = random(margin, sceneSize - margin);
    float ly = random(margin,sceneSize - margin);
    this.StartPos = new PVector(lx, ly);
  }
  
  void RandomizeAngle()
  {
    float a = random(0,6.28318);
    this.Angle = a;
  }
  
  void RandomizeLength()
  {
    float ll = random(initialSpread.x, initialSpread.y);
    this.Len = ll;
  }
  
  void RandomizeBaseVelocity()
  {
    float randomAngle = random(6.28318);
    float randomVelocityLength = random(baseVelocityRange.x, baseVelocityRange.y);
    float dx = cos(randomAngle) * randomVelocityLength;
    float dy = sin(randomAngle) * randomVelocityLength;
    this.BaseVelocity = new PVector(dx, dy);
  }
  
  void RandomizeVelocityModifiers()
  {
    for(int index = 0; index < nbBodies; ++index)
    {
      float rv = 1;//random(0,1);
      this.Velocities[index] = rv;
    }
  }
  
  void Randomize()
  {
    this.RandomizeStartPos();
    this.RandomizeAngle();
    this.RandomizeLength();
    this.RandomizeBaseVelocity();
    this.RandomizeVelocityModifiers();
  }
}

void Sign()
{
  String counter = ToHex(GetCount(counterSaveFileName));
  String signature = counter + " - By AntonMakesGames";
  float scale = 6;
  PVector size = new PVector(font.GetWidth(signature, scale), scale);
  PVector pos = new PVector(width - size.x - 10, height - scale * 1.3);
  font.Draw(signature, pos, scale);
}

Vec4 GetSignRect()
{
  String counter = ToHex(GetCount(counterSaveFileName));
  String signature = counter + " - By AntonMakesGames";
  float scale = 6;
  PVector size = new PVector(font.GetWidth(signature, scale), scale);
  PVector pos = new PVector(width - size.x - 10, height - scale * 1.3);
  return new Vec4(pos.x, pos.y, size.x, size.y);
}

// --------------------------------------------------------------
// SVG Font

SVGFont loadFontXML(String fileName)
{
  String acceptedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ?.-#";
  
  SVGFont result = new SVGFont();
  result.Glyphs = new HashMap<String, Glyph>();
  XML xml = loadXML(fileName);
  XML defs = xml.getChildren("defs")[0];
  XML font = defs.getChildren("font")[0];
  XML[] glyphs = font.getChildren("glyph");
  XML fontFace = font.getChildren("font-face")[0];
  float scale = fontFace.getFloat("units-per-em");
  
  for(int index = 0; index < glyphs.length; ++index)
  {
    String unicode = glyphs[index].getString("unicode");
    if(acceptedCharacters.indexOf(unicode) < 0)
    {
      continue;
    }
      
    ArrayList<GlyphNode> parsedNodes = new ArrayList<GlyphNode>();
    String stringPath = glyphs[index].getString("d");
    if(stringPath != null)
    {
      String[] splitted = split(stringPath, " ");
      
      int cursor = 0;
      while(cursor < splitted.length)
      {
        boolean isMove = splitted[cursor].equals("M");
        cursor++;
        float x = float(splitted[cursor]);
        cursor++;
        float y = float(splitted[cursor]);
        cursor++;
        GlyphNode node = new GlyphNode();
        node.IsMove = isMove;
        node.Position = new PVector(x/scale, -y/scale);
        parsedNodes.add(node);
      }
    }
    float w = glyphs[index].getFloat("horiz-adv-x");
    Glyph glyph = new Glyph();
    glyph.Unicode = unicode;
    glyph.Width = w / scale;
    glyph.Nodes = new GlyphNode[parsedNodes.size()];
    for(int nodeIndex = 0; nodeIndex < glyph.Nodes.length; ++nodeIndex)
    {
      glyph.Nodes[nodeIndex] = parsedNodes.get(nodeIndex);
    }

    result.Glyphs.put(unicode, glyph);
  }
  
  return result;
}

class SVGFont
{
  HashMap<String, Glyph> Glyphs;
  
  void Draw(String input, PVector position, float scale)
  {
    PVector currentPosition = new PVector(position.x, position.y + scale);
    int len = input.length();
    for(int index = 0; index < len; ++index)
    {
      String c = input.substring(index, index + 1);
      Glyph glyph = this.Glyphs.get("?");
      if(this.Glyphs.containsKey(c))
      {
        glyph = this.Glyphs.get(c);
      }
      
      glyph.Draw(currentPosition, scale);
      currentPosition.x += scale * glyph.Width;
    }
  }

  float GetWidth(String input, float scale)
  {
    int len = input.length();
    float w = 0;
    for(int index = 0; index < len; ++index)
    {
      String c = input.substring(index, index + 1);
      Glyph glyph = this.Glyphs.get("?");
      if(this.Glyphs.containsKey(c))
      {
        glyph = this.Glyphs.get(c);
      }
      
      w += scale * glyph.Width;
    }

    return w;
  }
}

class Glyph
{
  String Unicode;
  GlyphNode[] Nodes;
  float Width;

  void Draw(PVector position, float scale)
  {
    PVector currentPosition = new PVector(position.x, position.y);
    for(int index = 0; index < this.Nodes.length; ++index)
    {
      GlyphNode node = this.Nodes[index];
      PVector newPosition = new PVector(position.x + node.Position.x * scale, position.y + node.Position.y * scale);
      if(!node.IsMove)
      {
        line(currentPosition.x, currentPosition.y, newPosition.x, newPosition.y);
      }

      currentPosition = newPosition;
    }
  }
}

class GlyphNode
{
  boolean IsMove = false;
  PVector Position;
}

// ----------------------------------------------------------------------


// ------------------------------------------------------------------------------------
// CounterSave

int GetCount(String fileName)
{
    String[] strings = loadStrings(fileName);
    return int(strings[0]);
}

int IncrementSavedCounter(String fileName)
{
    int count = GetCount(fileName);
    PrintWriter output = createWriter(fileName);
    output.print(count + 1);
    output.close();
    return count;
}

String ToHex(int input)
{
    String charTable = "0123456789ABCDEF";
    String result = "";
    do
    {
        int rest = input % 16;
        result = charTable.charAt(rest) + result;
        input /= 16;
    }while(input > 0);

    return result;
}
// ------------------------------------------------------------------------------------