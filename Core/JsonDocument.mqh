//+------------------------------------------------------------------+
//|  Core/JsonDocument.mqh                                           |
//+------------------------------------------------------------------+
#ifndef MQL5_JSON_DOCUMENT_V10_H
#define MQL5_JSON_DOCUMENT_V10_H

#include <Object.mqh> // For CheckPointer

#include "JsonCore.mqh"
#include "JsonNode.mqh"
#include "JsonStreamParser.mqh"
#include "JsonParser.mqh"
#include "JsonTypes.mqh"

namespace MQL5_Json
{
//+------------------------------------------------------------------+
//|  HELPER FUNCTION IMPLEMENTATION (Required by JsonMerge)          |
//+------------------------------------------------------------------+
void JsonMergeHelper(JsonNode &target, const JsonNode &patch)
{
   if (!patch.IsObject() || !target.IsObject()) return;
   string keys[];
   patch.GetKeys(keys);
   for (int i=0; i < ArraySize(keys); i++)
   {
      string key = keys[i];
      JsonNode patch_value = patch.Get(key);
      if(!patch_value.IsValid()) continue;
      if (patch_value.IsNull())
      {
         target.Remove(key);
      }
      else
      {
         JsonNode target_child = target.Get(key);
         if (target_child.IsObject() && patch_value.IsObject())
         {
            JsonMergeHelper(target_child, patch_value);
         }
         else
         {
            target.Set(key, patch_value);
         }
      }
   }
}


//+------------------------------------------------------------------+
//|  CLASS DEFINITION                                                |
//+------------------------------------------------------------------+
class JsonDocument
{
private:
   Internal::CJsonDocument *m_impl;
   JsonDocument(const JsonDocument &other) {}
   void operator=(const JsonDocument &other) {}

public:
   JsonDocument();
   JsonDocument(Internal::CJsonDocument *impl);
   JsonDocument(JsonDocument &other); // Move constructor
   ~JsonDocument();
   void operator=(JsonDocument &other); // Move assignment

   Internal::CJsonDocument* _GetImpl() const
   {
      return m_impl;
   }
   void _SetRootImpl(Internal::CJsonValue* new_root)
   {
      if(CheckPointer(m_impl) != 0) m_impl.m_root = new_root;
   }

   bool       IsValid() const;
   JsonNode   GetRoot() const;
   JsonDocument Clone() const;
   string     ToString(bool pretty=false, bool escape_non_ascii=false) const;
   bool       SaveToFile(const string &path, bool pretty=true, bool escape=false, bool bom=true) const;
   JsonNode   CreateObjectNode();
   JsonNode   CreateArrayNode();
   JsonNode   operator[](const string &key) const;
   JsonNode   operator[](int index) const;
};

//+------------------------------------------------------------------+
//|  STANDALONE FACTORY FUNCTION IMPLEMENTATIONS                     |
//+------------------------------------------------------------------+
JsonDocument JsonParse(const string &text, JsonError &error, const JsonParseOptions &options)
{
   error.Clear();
   Internal::CJsonDocument *doc_impl = new Internal::CJsonDocument();
   if(!doc_impl)
   {
      error.message="Memory allocation failed";
      return JsonDocument(NULL);
   }
   Internal::CDomBuilderHandler handler(doc_impl);
   JsonStreamParser parser;
   if(!parser.Parse(text,GetPointer(handler),error,options))
   {
      delete doc_impl;
      return JsonDocument(NULL);
   }
   doc_impl.m_root = handler.GetRoot();
   if(!doc_impl.m_root && error.message=="")
   {
      error.message="Empty document";
      delete doc_impl;
      return JsonDocument(NULL);
   }
   return JsonDocument(doc_impl);
}

JsonDocument JsonFromFile(const string &filepath, JsonError &error, const JsonParseOptions &options)
{
   error.Clear();
   Internal::CJsonDocument *doc_impl = new Internal::CJsonDocument();
   if(!doc_impl)
   {
      error.message="Memory allocation failed";
      return JsonDocument(NULL);
   }
   JsonFileStreamParser parser;
   Internal::CDomBuilderHandler handler(doc_impl);
   if(!parser.Parse(filepath,GetPointer(handler),error,options))
   {
      delete doc_impl;
      return JsonDocument(NULL);
   }
   doc_impl.m_root = handler.GetRoot();
   if(!doc_impl.m_root && error.message=="")
   {
      error.message="Empty file";
      delete doc_impl;
      return JsonDocument(NULL);
   }
   return JsonDocument(doc_impl);
}

JsonDocument JsonNewObject()
{
   Internal::CJsonDocument *doc_impl = new Internal::CJsonDocument();
   if(!doc_impl) return JsonDocument(NULL);
   doc_impl.m_root = doc_impl.CreateNode(JSON_OBJECT);
   if(!doc_impl.m_root)
   {
      delete doc_impl;
      return JsonDocument(NULL);
   }
   return JsonDocument(doc_impl);
}

JsonDocument JsonNewArray()
{
   Internal::CJsonDocument *doc_impl = new Internal::CJsonDocument();
   if(!doc_impl) return JsonDocument(NULL);
   doc_impl.m_root = doc_impl.CreateNode(JSON_ARRAY);
   if(!doc_impl.m_root)
   {
      delete doc_impl;
      return JsonDocument(NULL);
   }
   return JsonDocument(doc_impl);
}

JsonDocument JsonMerge(const JsonDocument &target, const JsonDocument &patch)
{
   if(!target.IsValid()) return JsonDocument(NULL);
   JsonDocument result_doc = target.Clone();
   if(!result_doc.IsValid()) return JsonDocument(NULL);
   if(!patch.IsValid()) return result_doc;
   JsonNode result_root = result_doc.GetRoot();
   JsonNode patch_root = patch.GetRoot();
   if(result_root.IsObject() && patch_root.IsObject())
   {
      JsonMergeHelper(result_root, patch_root);
   }
   else
   {
      Internal::CJsonDocument* result_impl = result_doc._GetImpl();
      if(CheckPointer(result_impl) != 0 && patch_root.IsValid())
      {
         Internal::CJsonValue* new_root = patch_root.m_value.Clone(result_impl);
         result_doc._SetRootImpl(new_root);
      }
   }
   return result_doc;
}

} // End namespace MQL5_Json
#endif // MQL5_JSON_DOCUMENT_V10_H
