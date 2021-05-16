// Written by Anton Roy (AntonMakesGames)
import processing.svg.*;

GravityBody[] gravityBodies;
Body[] bodies;
int nbBodies = 200;
final float inkscapeFactor = 3.779528;

final float sceneSize = 792;
ArrayList<Vec2>[] trajectories;
Parameters savedParam, currentParam;
float drag = .99;
float noiseRange = .6;
float noiseZoom = .003;
Vec2 baseVelocityRange = new Vec2(0, 50);
float mainMass = 2000;

Vec2 initialSpread = new Vec2(0, 500);

boolean isRecording = false;

Vec2 centerOfMass;

void ApplyParam(Parameters param)
{
  spawnBodiesInCircle(param);
  
  background(250);
  circle(param.StartPos.x, param.StartPos.y, 5);
  println("("+param.StartPos.x+","+param.StartPos.y+")");
}

void spawnBodiesInLine(Parameters param)
{
  float ax = (sin(param.Angle) * param.Len) / nbBodies;
  float ay = (cos(param.Angle) * param.Len) / nbBodies;
  float dx = param.BaseVelocity.x;
  float dy = param.BaseVelocity.x;

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
    bodies[index] = new Body(cx + ax * radius, cy + ay * radius, ay * len, -ax * len);
    trajectories[index] = new ArrayList<Vec2>();
  }
}

void setup() {
  size(548, 377);
  gravityBodies = new GravityBody[1];
  gravityBodies[0] = new GravityBody(width/2f, height/2f, mainMass);
  bodies = new Body[nbBodies];
  trajectories = new ArrayList[nbBodies];
  Parameters param = new Parameters();
  param.Randomize();
  savedParam = param;
  currentParam = param;
  ApplyParam(param);
}

float time = 0;

void draw()
{
  stroke(0);
  circleCorner();
  if(isRecording)
  {
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
    
    endRecord();
    println("Stop recording");
    isRecording = false;
    
    return;
  }
  
  float dt = .1;
  time += dt;
  centerOfMass = new Vec2(0, 0);
  
  for(int index = 0; index < nbBodies; ++index)
  {
    Body body = bodies[index];
    body.Update(dt, gravityBodies);
    line(body.px,body.py,body.x,body.y);
    trajectories[index].add(new Vec2(body.px,body.py));
    centerOfMass.x += body.x;
    centerOfMass.y += body.y;
  }
  
  stroke(255,0,0);
  for(int index = 0; index < gravityBodies.length; ++index)
  {
    circle(gravityBodies[index].x,gravityBodies[index].y, 3);
  }
  
  stroke(0,0,255);
  centerOfMass.x /= nbBodies;
  centerOfMass.y /= nbBodies;
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
  
  if(key == 'o' && !isRecording)
  {
    println("Start recording");
    
    beginRecord(SVG, "GravityRecording.svg");
    isRecording = true;
  }
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

class Body
{
  float x,y,dx,dy,px,py;
  Body(float x,float y,float dx,float dy)
  {
    this.x = x;
    this.y = y;
    this.dx = dx;
    this.dy = dy;
    this.px = x;
    this.py = y;
  }
  
  void Update(float dt, GravityBody[] gBodies)
  {
    this.px = this.x;
    this.py = this.y;
    this.x += this.dx * dt;
    this.y += this.dy * dt;
    
    int nbG = gBodies.length;
    float accX = 0, accY = 0;
    for(int index = 0; index < nbG; ++index)
    {
      GravityBody body = gBodies[index];
      float dirx = body.x - this.px + this.dx * .5;
      float diry = body.y - this.py + this.dy * .5;
      float len2 = dirx * dirx + diry * diry;
      float len = sqrt(len2);
      accX += (dirx / len) * (body.w / len);
      accY += (diry / len) * (body.w / len);
    }
    
    if(noiseRange != 0)
    {
      this.dx += (noise(this.x * noiseZoom, this.y * noiseZoom, 0) * noiseRange * 2) - noiseRange;
      this.dy += (noise(this.x * noiseZoom, this.y * noiseZoom, 1) * noiseRange * 2) - noiseRange;
    }

    if(drag != 1)
    {
      this.dx = (this.dx + accX * dt) * drag;
      this.dy = (this.dy + accY * dt) * drag;
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
