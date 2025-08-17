//+------------------------------------------------------------------+
//|  Core/JsonDocument.mqh                                           |
//+------------------------------------------------------------------+
#ifndef MQL5_JSON_DOCUMENT_V10_H
#define MQL5_JSON_DOCUMENT_V10_H

#include <Object.mqh>

#include "JsonCore.mqh"
#include "JsonNode.mqh"
#include "JsonStreamParser.mqh"
#include "JsonParser.mqh"
#include "JsonTypes.mqh"
#include "JsonSerializer.mqh"
#include "JsonUtils.mqh"

namespace MQL5_Json
{
// ... (JsonMergeHelper function is unchanged, omitted for brevity)
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


class JsonDocument
{
private:
   Internal::CJsonDocument *m_impl;
   JsonDocument(const JsonDocument &other) {}

public:
   JsonDocument() : m_impl(NULL) {}
   JsonDocument(Internal::CJsonDocument *impl) : m_impl(impl) {}
   JsonDocument(JsonDocument &other)
   {
      m_impl = other.m_impl;
      other.m_impl = NULL;
   }
   ~JsonDocument()
   {
      if(CheckPointer(m_impl) == POINTER_DYNAMIC)
         delete m_impl;
   }
   void operator=(JsonDocument &other)
   {
      if(GetPointer(this) == GetPointer(other)) return;
      if(CheckPointer(m_impl) == POINTER_DYNAMIC) delete m_impl;
      m_impl = other.m_impl;
      other.m_impl = NULL;
   }

   Internal::CJsonDocument* _GetImpl() const
   {
      return m_impl;
   }
   void _SetRootImpl(Internal::CJsonValue* new_root)
   {
      if(CheckPointer(m_impl) != 0) m_impl.m_root = new_root;
   }

   bool IsValid() const
   {
      return CheckPointer(m_impl) != 0 && CheckPointer(m_impl.m_root) != 0;
   }
   JsonNode GetRoot() const
   {
      return JsonNode(IsValid() ? m_impl.m_root : NULL);
   }

   JsonDocument Clone() const
   {
      if(!IsValid()) return JsonDocument(NULL);
      Internal::CJsonDocument*d = new Internal::CJsonDocument();
      if(!d) return JsonDocument(NULL);
      d.m_root = m_impl.m_root.Clone(d);
      if(!d.m_root)
      {
         delete d;
         return JsonDocument(NULL);
      }
      return JsonDocument(d);
   }

   string ToString(bool pretty=false, bool escape_non_ascii=false) const
   {
      if(!IsValid()) return "";
      Internal::CJsonSerializer s;
      return s.Serialize(m_impl.m_root, pretty, escape_non_ascii);
   }

   //
   bool SaveToFile(const string &path, bool pretty=true, bool escape=false, bool bom=false) const
   {
      if(!IsValid()) return false;
      int h = FileOpen(path, FILE_WRITE|FILE_BIN|FILE_ANSI);
      if(h < 0) return false;
      string s = ToString(pretty, escape);
      uchar y[];
      Internal::JsonStringToUtf8Bytes(s, y, bom);
      bool k = true;
      if(ArraySize(y) > 0 && FileWriteArray(h, y) != (uint)ArraySize(y)) k = false;
      FileClose(h);
      return k;
   }

   JsonNode CreateObjectNode()
   {
      return JsonNode(IsValid() ? m_impl.CreateNode(JSON_OBJECT) : NULL);
   }
   JsonNode CreateArrayNode()
   {
      return JsonNode(IsValid() ? m_impl.CreateNode(JSON_ARRAY) : NULL);
   }
   JsonNode operator[](const string &key) const
   {
      return GetRoot().Get(key);
   }
   JsonNode operator[](int index) const
   {
      return GetRoot().At(index);
   }
};

//
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


}
#endif // MQL5_JSON_DOCUMENT_V10_H
//+------------------------------------------------------------------+
