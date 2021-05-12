Ball ball;
Square square;

void setup()
{
    size(300, 300);
    ball = new Ball(new vec2(10, 10), new vec2(2, 2));
    square = new Square(new vec2(120,140), 40);
}

void draw()
{
    float dt = .16;
    ball.Update(dt);

    background(200);
    stroke(0, 0, 255);
    circle(ball.Pos.x, ball.Pos.y, 5);
    
    if(square.IsIn(ball.Pos))
    {
        stroke(255, 255, 0);
    }
    else {
        stroke(255, 0, 0);
    }

    square.Draw();
}

class Ball
{
    vec2 Pos;
    vec2 Vel;
    vec2 Dir;

    Ball(vec2 pos, vec2 vel)
    {
        this.Pos = pos;
        this.Vel = vel;
        this.Dir = vel.Normal();
    }

    void Update(float dt)
    {
        this.Pos.Add(this.Vel);
    }   
}

class Square
{
    vec2 Corner;
    vec2 Dc;
    float Size;

    Square(vec2 pos, float s)
    {
        this.Corner = new vec2(pos);
        this.Size = s;
        this.Dc = new vec2(pos.x + s, pos.y + s);
    }

    boolean IsIn(vec2 p)
    {
        return !(p.x < this.Corner.x || p.y < this.Corner.y || p.x > (this.Corner.x + this.Size) || p.y > (this.Corner.y + this.Size));
    }

    void Draw()
    {
        float dx = this.Corner.x + this.Size;
        float dy = this.Corner.y + this.Size;
        line(this.Corner.x, this.Corner.y, dx, this.Corner.y);
        line(dx, this.Corner.y, dx, dy);
        line(dx, dy, this.Corner.x, dy);
        line(this.Corner.x, dy, this.Corner.x, this.Corner.y);
    }

    void BallInsideCollide(Ball ball, Collision col)
    {
        col.Normal.x = 0;
        col.Normal.y = 0;

        if(ball.Vel.x == 0)
        {
            if(ball.Pos.x == this.Corner.x || ball.Pos.x == this.Dc.x)
            {
                col.IsCollisioning = true;
                col.Pos.x = ball.Pos.x;
                col.Pos.y = ball.Pos.y;

            }
        }
        
        if(ball.Vel.y == 0)
        {
            if(ball.Pos.y == this.Corner.y || ball.Pos.y == this.Dc.y)
            {
                col.IsCollisioning = true;
                col.Pos.x = ball.Pos.x;
                col.Pos.y = ball.Pos.y;
            }
        }

        
    }
}

class Collision
{
    boolean IsCollisioning;
    vec2 Pos;
    vec2 Normal;
}

class vec2
{
    float x,y;

    vec2(float x, float y)
    {
        this.x = x; this.y = y;
    }

    vec2()
    {
        this(0, 0);
    }

    vec2(vec2 other)
    {
        this.x = other.x;
        this.y = other.y;
    }

    vec2 Add(vec2 other)
    {
        this.x += other.x;
        this.y += other.y;
        return this;
    }

    vec2 Mul(float scalar)
    {
        this.x *= scalar;
        this.y *= scalar;
        return this;
    }

    vec2 Div(float scalar)
    {
        this.x /= scalar;
        this.y /= scalar;
        return this;
    }

    float Magnitude()
    {
        return sqrt(this.x * this.x + this.y * this.y);
    }

    vec2 Normalize()
    {
        float mag = this.Magnitude();
        this.x /= mag;
        this.y /= mag;
        return this;
    }

    vec2 Normal()
    {
        return new vec2(this).Normalize();
    }

    float Dot(vec2 other)
    {
        return this.x * other.x + this.y * other.y;
    }

    boolean IsColinear(vec2 other)
    {
        return this.x * other.y - this.y * other.x == 0;
    }
}