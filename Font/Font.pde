
FontObject loadedFont;

void setup()
{
  size(500,500);
  loadedFont = loadFontXML("HersheySans1.svg");  
  background(225);
}

FontObject loadFontXML(String fileName)
{
  String acceptedCharacters = "abcdefghijklmnopqrstuvwxzABCDEFGHIJKLMNOPQRSTUVWXZ0123456789 ?.-";
  
  FontObject result = new FontObject();
  result.Glyphs = new HashMap<String, Glyph>();
  XML xml = loadXML(fileName);
  XML defs = xml.getChildren("defs")[0];
  XML font = defs.getChildren("font")[0];
  XML[] glyphs = font.getChildren("glyph");
  XML fontFace = font.getChildren("font-face")[0];
  float scale = fontFace.getFloat("units-per-em");
  
  for(int index = 0; index < glyphs.length; ++index)
  {
    String unicode = trim(glyphs[index].getString("unicode"));
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

void draw()
{
  pushMatrix();
  stroke(0);
  loadedFont.Draw("Hello World", new PVector(0,100) , 30);
  popMatrix();
}

class FontObject
{
  HashMap<String, Glyph> Glyphs;
  
  void Draw(String input, PVector position, float scale)
  {
    PVector currentPosition = new PVector(position.x, position.y);
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
