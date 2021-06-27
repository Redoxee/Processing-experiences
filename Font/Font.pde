String fileName = "HersheySans1.svg";

XML xml;

Glyph gly;

void setup()
{
  size(500,500);
  loadFontXML();  
  background(225);
}

void loadFontXML()
{
  xml = loadXML(fileName);
  XML defs = xml.getChildren("defs")[0];
  XML font = defs.getChildren("font")[0];
  XML[] glyphs = font.getChildren("glyph");
  XML fontFace = font.getChildren("font-face")[0];
  float scale = fontFace.getFloat("units-per-em");
  
  for(int index = 0; index < glyphs.length; ++index)
  {
    String unicode = trim(glyphs[index].getString("unicode"));
    if(unicode.equals("A"))
    {
      String stringPath = glyphs[index].getString("d");
      String[] splitted = split(stringPath, " ");
      ArrayList<GlyphNode> parsedNodes = new ArrayList<GlyphNode>();
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
        println("x " + node.Position.x  + " , y " + node.Position.y);
        parsedNodes.add(node);
      }

      float w = glyphs[index].getFloat("horiz-adv-x");
      Glyph glyph = new Glyph();
      glyph.Unicode = unicode;
      glyph.Width = w;
      glyph.Nodes = new GlyphNode[parsedNodes.size()];
      for(int nodeIndex = 0; nodeIndex < glyph.Nodes.length; ++nodeIndex)
      {
        glyph.Nodes[nodeIndex] = parsedNodes.get(nodeIndex);
      }

      gly = glyph;
    }
  }
}

void draw()
{
  pushMatrix();
  translate(250,250);
  stroke(0);
  gly.Draw(30);
  popMatrix();
}

class Glyph
{
  String Unicode;
  GlyphNode[] Nodes;
  float Width;

  void Draw(float scale)
  {
    PVector currentPosition = new PVector(0, 0);
    for(int index = 0; index < this.Nodes.length; ++index)
    {
      GlyphNode node = this.Nodes[index];
      if(!node.IsMove)
      {
        line(currentPosition.x * scale, currentPosition.y * scale, node.Position.x * scale, node.Position.y * scale);
      }

      currentPosition = node.Position;
    }
  }
}

class GlyphNode
{
  boolean IsMove = false;
  PVector Position;
}