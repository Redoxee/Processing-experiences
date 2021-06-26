// Written by Anton Roy (AntonMakesGames)
import processing.svg.*;

String exportFileName = "sdfRecording";

GravityBody[] gravityBodies;
Body[] bodies;
int nbBodies = 200;
final float inkscapeFactor = 3.779528;

final float sceneSize = 792;
ArrayList<Vec2>[] trajectories;
Parameters savedParam, currentParam;
float drag = 1.;
float noiseRange = 0;
float noiseZoom = .003;
Vec2 baseVelocityRange = new Vec2(1, 10);
float mainMass = 2000;

Vec2 initialSpread = new Vec2(0, 400);

float sdfPerturbation = .3;

boolean isRecording = false;

Vec2 centerOfMass;

String fieldName = "MoreCircles.jpg";
float fieldFactor = -40.;
PImage sdf;
Vec4[] vecSdf;

enum States
{UpdatingBodies, PreparingPainting}
States state;

void ApplyParam(Parameters param)
{
  //spawnBodiesInCircle(param);
  spawnBodiesInSideLine(param);
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
    trajectories[index] = new ArrayList<Vec2>();
  }
}

void spawnBodiesInCircle(Parameters param)
{
  float cx = width / 2;
  float cy = height / 2;
  float radius = param.Len;
  
  float len2 = param.BaseVelocity.x * param.BaseVelocity.x + param.BaseVelocity.y * param.BaseVelocity.y;
  float len = sqrt(len2);

  for(int index = 0; index < nbBodies; ++index)
  {
    float f = (float)index / (float)nbBodies * 6.28318;
    float ax = cos(f);
    float ay = sin(f);
    float px = cx + ax * radius;
    float py = cy + ay * radius;
    bodies[index] = new Body(px, py, (cx - px) * len / radius, (cy - py) * len / radius);
    trajectories[index] = new ArrayList<Vec2>();
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
      trajectories[index] = new ArrayList<Vec2>();
    }
  }
}

void spawnBodiesInSideLine(Parameters param)
{
  float halfWidth = (float)width/2.0;
  float shrnk = .8;

  int halfBodies = nbBodies / 2;

  boolean mirror = false;
  int loopcount = mirror ? halfBodies : nbBodies;

  for(int index = 0; index < loopcount; ++index)
  {
    bodies[index] = new Body(index / (float)loopcount * (float)width * shrnk + halfWidth * (1 - shrnk), 0, 0, param.BaseVelocity.x);
    trajectories[index] = new ArrayList<Vec2>();

    if(mirror)
    {
      bodies[index + halfBodies] = new Body(index / (float)loopcount * (float)width * shrnk + halfWidth * (1 - shrnk), height, 0, -param.BaseVelocity.x);
      trajectories[index + halfBodies] = new ArrayList<Vec2>();
    }
  }
}

void setup() {
  size(548, 377);

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
      float fr = (float)r / 128f - 1f;
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
      trajectories[index].add(new Vec2(body.px,body.py));
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
      String fileName = GetAvailableFileName(exportFileName, "svg");
      println("Start recording " + fileName);
      beginRecord(SVG, fileName);
    }
    
    circleCorner();
    
    for(int index = 0; index < nbBodies;++index)
    {
      int nbPoints = trajectories[index].size();
      Vec2 p1 = trajectories[index].get(0);
      for(int i = 1; i < nbPoints; ++i)
      {
        Vec2 p2 = trajectories[index].get(i);
        if(p1.InsideScreen() && p2.InsideScreen())
        {
          line(p1.x, p1.y, p2.x, p2.y);
        }
        p1 = p2;
      }
    }
    
    if(isRecording)
    { 
      endRecord();
      println("Stop recording");
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
      this.SimplifyLines();
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

class Body
{
  float x,y,px,py;
  Vec2 speed;
  boolean isInZone;
  boolean dead;
  Body(float x,float y,float dx,float dy)
  {
    this.x = x;
    this.y = y;
    this.speed = new Vec2(dx, dy);
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
    //this.dx = sdf.z * fieldFactor;
    //this.dy = sdf.w * fieldFactor;

    if(inZone != this.isInZone)
    {
      if(inZone)
      {
        this.speed = this.speed.Rotate(sdfPerturbation);
      }
      else
      {
        this.speed = this.speed.Rotate(-sdfPerturbation);
      }
    }

    this.x += this.speed.x * dt;
    this.y += this.speed.y * dt;

    this.isInZone = inZone;

    if(noiseRange != 0)
    {
      this.speed.x += (noise(this.x * noiseZoom, this.y * noiseZoom, 0) * noiseRange * 2) - noiseRange;
      this.speed.y += (noise(this.x * noiseZoom, this.y * noiseZoom, 1) * noiseRange * 2) - noiseRange;
    }

    if(drag != 1)
    {
      this.speed.x = (this.speed.x * dt) * drag;
      this.speed.y = (this.speed.y * dt) * drag;
    }
  }
}

class Vec2
{
  float x,y;
  Vec2(float x, float y)
  {
    this.x = x;
    this.y = y;
  }
  
  Vec2(Vec2 o)
  {
    this.x = o.x;
    this.y = o.y;
  }
  
  boolean InsideScreen()
  {
    return this.x >=0 && this.y >= 0 && this.x <= width && this.y <= height;
  }

  Vec2 Rotate(float a)
  {
    float ca = cos(a);
    float sa = sin(a);
    return new Vec2(ca * this.x - sa * this.y, sa * this.x + ca * this.y);
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
  Vec2 StartPos;
  float Angle, Len;
  Vec2 BaseVelocity;
  float[] Velocities;
  
  Parameters()
  {
    this.StartPos = new Vec2(0, 0);
    this.Angle = 0;
    this.Len = 0;
    this.BaseVelocity = new Vec2(0, 0);
    this.Velocities = new float[nbBodies];
  }
  
  Parameters(Parameters other)
  {
    this.StartPos = new Vec2(other.StartPos);
    this.Angle = other.Angle;
    this.Len = other.Len;
    this.BaseVelocity = new Vec2(other.BaseVelocity);
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
    this.StartPos = new Vec2(lx, ly);
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
    this.BaseVelocity = new Vec2(dx, dy);
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
