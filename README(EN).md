# MQL5 JSON Library (JsonLib) v10.0


A powerful, feature-rich library designed specifically for parsing, manipulating, and serializing JSON data within the MQL5 environment. It provides a simple and intuitive Document Object Model (DOM) API, aiming to make the JSON handling experience in MQL5 comparable to modern programming languages like JavaScript and Python.

This library is capable of handling a wide range of tasks, from reading simple EA configurations to complex real-time data exchange between systems.

## ✨ Features

-   **Powerful Parsing & Creation**:
    -   Reliably parse JSON from strings or files (`JsonParse`, `JsonFromFile`).
    -   Supports **JSON5** features like comments and trailing commas for enhanced compatibility.
    -   Build JSON from scratch with a concise API (`JsonNewObject`, `JsonNewArray`).
-   **Intuitive Data Manipulation**:
    -   Access data like a JS object or Python dictionary using keys (`node["key"]`) and indices (`node[0]`).
    -   Safe type casting (`AsInt(defaultValue)`, `AsString(defaultValue)`) prevents crashes from type mismatches or non-existent paths.
    -   Freely add, update, or remove JSON elements (`Set`, `Add`, `Remove`).
-   **Advanced Querying & Processing**:
    -   Built-in **JSON Pointer** (`.Query()`) and **JSONPath** (`.SelectNodes()`) query engines to easily extract data from complex structures.
    -   Includes a **Stream Parser** (`JsonStreamParser`) for processing gigabyte-scale JSON files with extremely low memory usage.
    -   Offers advanced utilities like document cloning (`.Clone()`) and deep merging (`JsonMerge`).
-   **Safe & Robust**:
    -   **Automatic Memory Management** (RAII), where `JsonDocument` manages the lifecycle of all nodes, fundamentally eliminating memory leaks.
    -   Cross-document operations automatically perform deep copies, preventing dangling pointers and data corruption.
    -   Detailed error reporting, including line and column numbers, for rapid debugging.

## 📦 Installation

1.  Download the source code from this repository.
2.  Copy the entire `Include/MQL5-Json` folder into your MQL5 data directory, under `\MQL5\Include\`.
3.  In your code, include the main header file:

    mql5
    #include <MQL5-Json/JsonLib.mqh>
   

## 🚀 Quick Start

Here is a simple example that demonstrates how to parse a string, access data, create a new JSON document, and serialize it.

```mql5
#include <MQL5-Json/JsonLib.mqh>

void OnStart()
{
    string jsonText = "{ \"name\": \"John Doe\", \"age\": 30, \"isStudent\": false, \"courses\": [\"MQL5\", \"C++\"] }";

    // 1. Parse the JSON string (must use the MQL5_Json:: namespace prefix)
    MQL5_Json::JsonError error;
    MQL5_Json::JsonParseOptions options;
    MQL5_Json::JsonDocument doc = MQL5_Json::JsonParse(jsonText, error, options);

    // 2. Always check if the document is valid after parsing
    if (!doc.IsValid())
    {
        Print("Failed to parse JSON: ", error.ToString());
        return;
    }

    // 3. Access the data
    MQL5_Json::JsonNode root = doc.GetRoot();
    string name = root.Get("name").AsString("Unknown");
    long   age  = root.Get("age").AsInt(0);
    bool   isStudent = root["isStudent"].AsBool(true); // The [] operator can also be used

    PrintFormat("Name: %s, Age: %d, Is Student: %s", name, age, isStudent ? "Yes" : "No");

    // 4. Create a new JSON document
    MQL5_Json::JsonDocument newDoc = MQL5_Json::JsonNewObject();
    newDoc.GetRoot().Set("status", "OK");
    newDoc.GetRoot().Set("code", 200);

    // 5. Serialize the new JSON (in pretty format)
    Print("Newly created JSON:\n", newDoc.ToString(true));
}


## 💡 Core Concepts & Best Practices

> **Warning:** To ensure your project integrates smoothly and runs stably, you must adhere to the following rules.

1.  **Namespace (Crucial!)**
    -   All classes and functions in this library are encapsulated within the `MQL5_Json` namespace.
    -   In `.mqh` header files, you **must** use fully qualified names, e.g., `MQL5_Json::JsonDocument`. Failure to do so will result in a `'JsonNode' - declaration without type` compilation error.
    -   **Correct Example**: `MQL5_Json::JsonDocument doc = MQL5_Json::JsonNewObject();`

2.  **Pass Objects by Reference**
    -   The MQL5 language mandates that all class objects **must** be passed by reference (`&`) when used as function parameters.
    -   **Correct Example**: `void myFunction(MQL5_Json::JsonNode &node);`
    -   Failure to do so will result in an `'objects are passed by reference only'` compilation error.

3.  **Memory & Lifecycle**
    -   `JsonDocument` **owns** the data; `JsonNode` is just a **view** or a reference.
    -   If a `JsonDocument` object is destroyed, all of its associated `JsonNode`s will become invalid.

## 📖 Advanced Usage Examples

<details>
<summary><b>🔹 Creating a Complex JSON Object</b></summary>

mql5
void CreateComplexJson()
{
   MQL5_Json::JsonDocument doc = MQL5_Json::JsonNewObject();
   MQL5_Json::JsonNode root = doc.GetRoot();

   root.Set("product_id", 12345);
   root.Set("available", true);

   // Create a child object
   MQL5_Json::JsonNode specs = doc.CreateObjectNode();
   specs.Set("color", "black");
   specs.Set("weight_kg", 1.25);
   root.Set("specifications", specs);

   // Create an array
   MQL5_Json::JsonNode tags = doc.CreateArrayNode();
   tags.Add("electronics");
   tags.Add("gadget");
   root.Set("tags", tags);

   Print("Created JSON:\n", doc.ToString(true));
}

</details>

<details>
<summary><b>🔹 Querying Data with JSON Pointer and JSONPath</b></summary>

mql5
void QueryData()
{
   string text = "{ \"store\": { \"book\": [ { \"title\": \"MQL5 Basics\" }, { \"title\": \"Advanced Algos\" } ] } }";
   MQL5_Json::JsonDocument doc = MQL5_Json::JsonParse(text, {}, {});
   if(!doc.IsValid()) return;
   
   MQL5_Json::JsonNode root = doc.GetRoot();

   // 1. Use JSON Pointer (RFC 6901) for precise, single-node lookups
   string first_title = root.Query("/store/book/0/title").AsString();
   Print("JSON Pointer Result: ", first_title);

   // 2. Use JSONPath to query for multiple nodes that match a condition
   MQL5_Json::JsonNode nodes[];
   MQL5_Json::JsonError error;
   int count = root.SelectNodes(nodes, "$.store.book[*].title", error);
   
   PrintFormat("JSONPath found %d titles:", count);
   for(int i = 0; i < count; i++)
   {
      Print(i, ": ", nodes[i].AsString());
   }
}

</details>

<details>
<summary><b>🔹 Stream Parsing Large Files (Low Memory Usage) - Full Implementation</b></summary>

mql5
// Define a handler class for JSON events that fully implements the IJsonStreamHandler interface
class CTradeCounter : public MQL5_Json::IJsonStreamHandler
{
private:
   int m_count;
   bool m_is_symbol_key; // State variable to track if the previous key was "symbol"

public:
   // Constructor
   CTradeCounter() : m_count(0), m_is_symbol_key(false) {}
   
   // Get the final count
   int GetCount() const { return m_count; }

   //--- Full implementation of the IJsonStreamHandler interface ---
   
   bool OnStartDocument() override 
   { 
      // Reset counter and state at the start of the document
      m_count = 0; 
      m_is_symbol_key = false; 
      return true; // Return true to continue parsing
   }
   
   bool OnEndDocument() override { return true; } // End of document, no special action
   
   bool OnStartObject() override { return true; } // Encountered '{'
   
   bool OnEndObject() override { return true; }   // Encountered '}'
   
   bool OnStartArray() override { return true; }  // Encountered '['
   
   bool OnEndArray() override { return true; }    // Encountered ']'
   
   bool OnKey(const string &key) override 
   {
      // When a key is parsed, check if it is the "symbol" we care about
      m_is_symbol_key = (key == "symbol");
      return true;
   }
   
   bool OnString(const string &value) override
   {
      // When a string value is parsed, check if the previous key was "symbol"
      // and if the string's value is "EURUSD"
      if(m_is_symbol_key && value == "EURUSD") 
      {
         m_count++; // Increment the counter
      }
      m_is_symbol_key = false; // Reset state after processing to avoid affecting subsequent elements
      return true;
   }
   
   bool OnNumber(const double value) override 
   { 
      m_is_symbol_key = false; // If a key is followed by a non-string, reset the state
      return true; 
   }
   
   bool OnBool(const bool value) override 
   { 
      m_is_symbol_key = false;
      return true; 
   }
   
   bool OnNull() override 
   { 
      m_is_symbol_key = false;
      return true; 
   }
};

void TestStreamParser()
{
   // Simulate the content of a very large JSON file
   string big_json_content = "[{\"symbol\":\"EURUSD\",\"price\":1.1}, {\"symbol\":\"GBPUSD\"}, {\"symbol\":\"EURUSD\",\"price\":1.2}]";
   
   MQL5_Json::JsonStreamParser parser;
   CTradeCounter *handler = new CTradeCounter();
   MQL5_Json::JsonError error;

   // Execute the stream parsing
   if(parser.Parse(big_json_content, handler, error))
   {
      Print("Stream parser found EURUSD trade count: ", handler.GetCount());
   }
   else
   {
      Print("Stream parsing failed: ", error.ToString());
   }
   
   delete handler; // Don't forget to free the memory
}

</details>

## ✍️ Author

**ding9736**

-   [MQL5 Profile](https://www.mql5.com/en/users/ding9736)

## 📜 License

This project is licensed under the [MIT License](LICENSE).