# MQL5 JSON Library (JsonLib) v10.0


一个功能强大、特性丰富的库，专为在MQL5环境中解析、操作和序列化JSON数据而设计。它提供了一套简单直观的文档对象模型(DOM) API，旨在让MQL5中的JSON处理体验媲美JavaScript、Python等现代编程语言。

本库能够胜任从简单的EA配置读取到复杂的跨系统实时数据交换等各种任务。

## ✨ 特性

-   **强大的解析与创建**:
    -   从字符串或文件可靠地解析JSON (`JsonParse`, `JsonFromFile`)。
    -   支持 **JSON5** 的部分特性，如注释和末尾逗号，增强兼容性。
    -   使用简洁的API (`JsonNewObject`, `JsonNewArray`) 从零开始构建JSON。
-   **直观的数据操作**:
    -   像JS对象或Python字典一样，通过键 (`node["key"]`) 和索引 (`node[0]`) 访问数据。
    -   安全的类型转换 (`AsInt(defaultValue)`, `AsString(defaultValue)`)，防止程序因类型不匹配或路径不存在而崩溃。
    -   自由地添加、更新或删除JSON中的元素 (`Set`, `Add`, `Remove`)。
-   **高级查询与处理**:
    -   内置 **JSON Pointer** (`.Query()`) 和 **JSONPath** (`.SelectNodes()`) 查询引擎，轻松从复杂结构中提取数据。
    -   提供 **流式解析器** (`JsonStreamParser`)，能以极低的内存占用处理GB级的超大JSON文件。
    -   提供文档克隆 (`.Clone()`) 和深度合并 (`JsonMerge`) 等高级工具。
-   **安全与健壮**:
    -   **自动内存管理** (RAII)，`JsonDocument` 管理所有节点生命周期，从根本上杜绝内存泄漏。
    -   跨文档操作自动进行深度拷贝，防止悬挂指针和数据污染。
    -   详尽的错误报告，包含行号、列号，便于快速定位问题。

## 📦 安装

1.  下载本仓库的源代码。
2.  将 `Include/MQL5-Json` 文件夹完整复制到您的MQL5数据目录的 `\MQL5\Include\` 文件夹下。
3.  在您的代码中，使用 `#include` 引入主头文件：

    ```mql5
    #include <MQL5-Json/JsonLib.mqh>
    ```

## 🚀 快速上手

下面是一个简单的示例，展示了如何解析字符串、访问数据、创建新JSON并将其序列化。

mql5
#include <MQL5-Json/JsonLib.mqh>

void OnStart()
{
    string jsonText = "{ \"name\": \"John Doe\", \"age\": 30, \"isStudent\": false, \"courses\": [\"MQL5\", \"C++\"] }";

    // 1. 解析JSON字符串 (必须使用 MQL5_Json:: 命名空间前缀)
    MQL5_Json::JsonError error;
    MQL5_Json::JsonParseOptions options;
    MQL5_Json::JsonDocument doc = MQL5_Json::JsonParse(jsonText, error, options);

    // 2. 解析后务必检查文档是否有效
    if (!doc.IsValid())
    {
        Print("解析JSON失败: ", error.ToString());
        return;
    }

    // 3. 访问数据
    MQL5_Json::JsonNode root = doc.GetRoot();
    string name = root.Get("name").AsString("Unknown");
    long   age  = root.Get("age").AsInt(0);
    bool   isStudent = root["isStudent"].AsBool(true); // 也可以使用 [] 操作符

    PrintFormat("Name: %s, Age: %d, Is Student: %s", name, age, isStudent ? "Yes" : "No");

    // 4. 创建一个新的JSON文档
    MQL5_Json::JsonDocument newDoc = MQL5_Json::JsonNewObject();
    newDoc.GetRoot().Set("status", "OK");
    newDoc.GetRoot().Set("code", 200);

    // 5. 序列化新JSON (美化格式)
    Print("新创建的JSON:\n", newDoc.ToString(true));
}


## 💡 核心概念与最佳实践

> **警告：** 为了确保您的项目能够顺利集成并稳定运行，请务必遵守以下规则。

1.  **命名空间 (至关重要!)**
    -   本库的所有类和函数都封装在 `MQL5_Json` 命名空间中。
    -   在 `.mqh` 头文件中，**必须**使用完全限定名称，例如 `MQL5_Json::JsonDocument`。否则将导致 `'JsonNode' - declaration without type` 编译错误。
    -   **正确示例**: `MQL5_Json::JsonDocument doc = MQL5_Json::JsonNewObject();`

2.  **对象参数通过引用传递**
    -   MQL5语言规定，所有类对象在作为函数参数传递时，**必须**通过引用 (`&`) 传递。
    -   **正确示例**: `void myFunction(MQL5_Json::JsonNode &node);`
    -   否则将导致 `'objects are passed by reference only'` 编译错误。

3.  **内存与生命周期**
    -   `JsonDocument` **拥有**数据，`JsonNode` 只是一个**视图**或引用。
    -   如果一个 `JsonDocument` 对象被销毁，其下所有的 `JsonNode` 都会失效。

## 📖 高级用法示例

<details>
<summary><b>🔹 创建复杂的JSON对象</b></summary>

mql5
void CreateComplexJson()
{
   MQL5_Json::JsonDocument doc = MQL5_Json::JsonNewObject();
   MQL5_Json::JsonNode root = doc.GetRoot();

   root.Set("product_id", 12345);
   root.Set("available", true);

   // 创建一个子对象
   MQL5_Json::JsonNode specs = doc.CreateObjectNode();
   specs.Set("color", "black");
   specs.Set("weight_kg", 1.25);
   root.Set("specifications", specs);

   // 创建一个数组
   MQL5_Json::JsonNode tags = doc.CreateArrayNode();
   tags.Add("electronics");
   tags.Add("gadget");
   root.Set("tags", tags);

   Print("创建的JSON:\n", doc.ToString(true));
}

</details>

<details>
<summary><b>🔹 使用JSON Pointer和JSONPath查询数据</b></summary>

mql5
void QueryData()
{
   string text = "{ \"store\": { \"book\": [ { \"title\": \"MQL5 Basics\" }, { \"title\": \"Advanced Algos\" } ] } }";
   MQL5_Json::JsonDocument doc = MQL5_Json::JsonParse(text, {}, {});
   if(!doc.IsValid()) return;
   
   MQL5_Json::JsonNode root = doc.GetRoot();

   // 1. 使用 JSON Pointer (RFC 6901) 精确获取单个节点
   string first_title = root.Query("/store/book/0/title").AsString();
   Print("JSON Pointer 结果: ", first_title);

   // 2. 使用 JSONPath 批量查询符合条件的节点
   MQL5_Json::JsonNode nodes[];
   MQL5_Json::JsonError error;
   int count = root.SelectNodes(nodes, "$.store.book[*].title", error);
   
   PrintFormat("JSONPath 查询到 %d 个标题:", count);
   for(int i = 0; i < count; i++)
   {
      Print(i, ": ", nodes[i].AsString());
   }
}

</details>

<details>
<summary><b>🔹 流式解析大文件 (低内存占用) - 完整实现</b></summary>

mql5
// 定义一个处理JSON事件的处理器类，完整实现 IJsonStreamHandler 接口
class CTradeCounter : public MQL5_Json::IJsonStreamHandler
{
private:
   int m_count;
   bool m_is_symbol_key; // 状态变量，用于跟踪前一个key是否为"symbol"

public:
   // 构造函数
   CTradeCounter() : m_count(0), m_is_symbol_key(false) {}
   
   // 获取最终计数结果
   int GetCount() const { return m_count; }

   //--- IJsonStreamHandler 接口的完整实现 ---
   
   bool OnStartDocument() override 
   { 
      // 在文档开始时重置计数器和状态
      m_count = 0; 
      m_is_symbol_key = false; 
      return true; // 返回true继续解析
   }
   
   bool OnEndDocument() override { return true; } // 文档结束，无特殊操作
   
   bool OnStartObject() override { return true; } // 遇到 '{'
   
   bool OnEndObject() override { return true; }   // 遇到 '}'
   
   bool OnStartArray() override { return true; }  // 遇到 '['
   
   bool OnEndArray() override { return true; }    // 遇到 ']'
   
   bool OnKey(const string &key) override 
   {
      // 当解析到一个键时，检查它是否是我们关心的 "symbol"
      m_is_symbol_key = (key == "symbol");
      return true;
   }
   
   bool OnString(const string &value) override
   {
      // 当解析到一个字符串值时，检查前一个键是否是"symbol"
      // 并且该字符串的值是否为 "EURUSD"
      if(m_is_symbol_key && value == "EURUSD") 
      {
         m_count++; // 计数器加一
      }
      m_is_symbol_key = false; // 处理完后重置状态，避免影响后续解析
      return true;
   }
   
   bool OnNumber(const double value) override 
   { 
      m_is_symbol_key = false; // 如果键后面跟的不是字符串，重置状态
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
   // 模拟一个非常大的JSON文件内容
   string big_json_content = "[{\"symbol\":\"EURUSD\",\"price\":1.1}, {\"symbol\":\"GBPUSD\"}, {\"symbol\":\"EURUSD\",\"price\":1.2}]";
   
   MQL5_Json::JsonStreamParser parser;
   CTradeCounter *handler = new CTradeCounter();
   MQL5_Json::JsonError error;

   // 执行流式解析
   if(parser.Parse(big_json_content, handler, error))
   {
      Print("流式解析找到 EURUSD 交易数量: ", handler.GetCount());
   }
   else
   {
      Print("流式解析失败: ", error.ToString());
   }
   
   delete handler; // 不要忘记释放内存
}

</details>

## ✍️ 作者

**ding9736**

-   [MQL5 Profile](https://www.mql5.com/en/users/ding9736)

## 📜 许可

该项目根据 [MIT 许可证](LICENSE) 授权。