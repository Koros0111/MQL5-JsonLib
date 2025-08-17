//+------------------------------------------------------------------+
//|  Core/JsonParser.mqh                                         |
//+------------------------------------------------------------------+

#ifndef MQL5_JSON_INTERNAL_PARSER_V10_H
#define MQL5_JSON_INTERNAL_PARSER_V10_H


#include "JsonCore.mqh"
#include "JsonTypes.mqh"

namespace MQL5_Json
{
namespace Internal
{

class CDomBuilderHandler : public MQL5_Json::IJsonStreamHandler
{
private:
   CJsonDocument *m_doc;
   CJsonValue    *m_stack[];
   int           m_top;
   string        m_current_key;

   CJsonValue *Peek()
   {
      return (m_top >= 0) ? m_stack[m_top] : NULL;
   }
   void Pop()
   {
      if(m_top >= 0)
      {
         m_top--;
      }
   }

   void Push(CJsonValue *value)
   {
      AddValue(value);
      if(value.m_type == JSON_ARRAY || value.m_type == JSON_OBJECT)
      {
         m_top++;
         if(ArraySize(m_stack) <= m_top) ArrayResize(m_stack, m_top + 1);
         m_stack[m_top] = value;
      }
   }

   bool AddValue(CJsonValue *value)
   {
      CJsonValue *parent = Peek();
      if(!parent)
      {
         if(ArraySize(m_stack) == 0) ArrayResize(m_stack, 1);
         m_stack[0] = value;
      }
      else if(parent.m_type == JSON_ARRAY)
      {
         parent.Add(value);
      }
      else if(parent.m_type == JSON_OBJECT)
      {
         parent.Set(m_current_key, value);
      }
      return true;
   }

public:
   CDomBuilderHandler(CJsonDocument *doc) : m_doc(doc), m_top(-1) {}
   CJsonValue *GetRoot()
   {
      return (ArraySize(m_stack) > 0) ? m_stack[0] : NULL;
   }

   bool OnStartDocument() override
   {
      ArrayFree(m_stack);
      m_top = -1;
      return true;
   }
   bool OnEndDocument() override
   {
      return true;
   }
   bool OnStartObject() override
   {
      CJsonValue *o = m_doc.CreateNode(JSON_OBJECT);
      if(!o) return false;
      Push(o);
      return true;
   }
   bool OnEndObject() override
   {
      Pop();
      return true;
   }
   bool OnStartArray() override
   {
      CJsonValue *a = m_doc.CreateNode(JSON_ARRAY);
      if(!a) return false;
      Push(a);
      return true;
   }
   bool OnEndArray() override
   {
      Pop();
      return true;
   }
   bool OnKey(const string &key) override
   {
      m_current_key = key;
      return true;
   }
   bool OnString(const string &value) override
   {
      CJsonValue *s=m_doc.CreateNode(JSON_STRING);
      if(!s)return false;
      s.m_str=value;
      return AddValue(s);
   }
   bool OnNumber(const string &value, ENUM_JSON_TYPE t) override
   {
      CJsonValue *n=m_doc.CreateNode(t);
      if(!n)return false;
      n.m_num_str=value;
      if(t==JSON_INT)n.m_int=StringToInteger(value);
      else n.m_double=StringToDouble(value);
      return AddValue(n);
   }
   bool OnBool(bool value) override
   {
      CJsonValue *b=m_doc.CreateNode(JSON_BOOL);
      if(!b)return false;
      b.m_bool=value;
      return AddValue(b);
   }
   bool OnNull() override
   {
      CJsonValue *n=m_doc.CreateNode(JSON_NULL);
      if(!n)return false;
      return AddValue(n);
   }
};

} // End namespace Internal
} // End namespace MQL5_Json
#endif // MQL5_JSON_INTERNAL_PARSER_V10_H
