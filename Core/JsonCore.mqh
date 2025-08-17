//+------------------------------------------------------------------+
//|  Core/JsonCore.mqh                                               |
//+------------------------------------------------------------------+

#ifndef MQL5_JSON_INTERNAL_CORE_V10_H
#define MQL5_JSON_INTERNAL_CORE_V10_H

namespace MQL5_Json
{

class JsonNode;
class JsonDocument;

enum ENUM_JSON_TYPE
{
   JSON_NULL, JSON_BOOL, JSON_INT, JSON_DOUBLE,
   JSON_STRING, JSON_ARRAY, JSON_OBJECT, JSON_INVALID
};

// --- Structures ---
struct JsonError
{
   int    line;
   int    column;
   string message;
   string context;

   void Clear()
   {
      line=0;
      column=0;
      message="";
      context="";
   }
   string ToString() const
   {
      if(message=="") return "No error";
      string near = (context != "") ? " near '" + context + "'" : "";
      return StringFormat("Line %d, Col %d: %s%s", line, column, message, near);
   }
};

struct JsonParseOptions
{
   bool strict_unicode;
   bool allow_comments;
   bool allow_trailing_commas;
   uint max_depth;

   JsonParseOptions()
   {
      strict_unicode=false;
      allow_comments=false;
      allow_trailing_commas=false;
      max_depth=64;
   }
};

// --- Interfaces ---
interface IJsonObjectVisitor
{
   void Visit(const string &key, const JsonNode &value);
};
interface IJsonArrayVisitor
{
   void Visit(int index, const JsonNode &item);
};

interface IJsonStreamHandler
{
   bool OnStartDocument();
   bool OnEndDocument();
   bool OnStartObject();
   bool OnEndObject();
   bool OnStartArray();
   bool OnEndArray();
   bool OnKey(const string &key);
   bool OnString(const string &value);
   bool OnNumber(const string &value, ENUM_JSON_TYPE type_hint);
   bool OnBool(bool value);
   bool OnNull();
};


namespace Internal
{
// Forward-declare internal classes
class CJsonValue;
class CJsonDocument;

interface ICharacterStreamReader
{
   bool   IsEOF() const;
   int    Line() const;
   int    Column() const;
   ushort Peek();
   ushort Next();
   bool   Prev();
   string GetContext(int length) const;
};
}

} // End namespace MQL5_Json
#endif // MQL5_JSON_INTERNAL_CORE_V10_H
