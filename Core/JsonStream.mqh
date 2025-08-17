//+------------------------------------------------------------------+
//|  Core/JsonStream.mqh                                             |
//+------------------------------------------------------------------+

#ifndef MQL5_JSON_INTERNAL_STREAM_V10_H
#define MQL5_JSON_INTERNAL_STREAM_V10_H

#include "JsonCore.mqh"

namespace MQL5_Json
{
namespace Internal
{

class StringStreamReader : public ICharacterStreamReader
{
private:
   string m_text;
   int m_len, m_pos, m_line, m_col;
public:
   StringStreamReader(const string &text): m_text(text), m_len(StringLen(text)), m_pos(0), m_line(1), m_col(1) {}

   bool IsEOF() const override
   {
      return m_pos >= m_len;
   }
   int  Line() const override
   {
      return m_line;
   }
   int  Column() const override
   {
      return m_col;
   }

   ushort Peek() override
   {
      return IsEOF() ? 0 : StringGetCharacter(m_text, m_pos);
   }

   ushort Next() override
   {
      if(IsEOF()) return 0;
      ushort c = StringGetCharacter(m_text, m_pos++);
      if(c == '\n')
      {
         m_line++;
         m_col = 1;
      }
      else
      {
         m_col++;
      }
      return c;
   }

   bool Prev() override
   {
      if (m_pos > 0)
      {
         m_pos--;
         if(m_col > 1) m_col--;
         return true;
      }
      return false;
   }

   string GetContext(int size) const override
   {
      int start = MathMax(0, m_pos - size);
      int end = MathMin(m_len, m_pos + size);
      return StringSubstr(m_text, start, end - start);
   }
};

class FileStreamReader : public ICharacterStreamReader
{
private:
   int m_file_handle;
   uchar m_buffer[];
   int m_buf_pos, m_buf_lim;
   int m_line, m_col;
   bool m_is_eof;
   ushort m_peek_char;

   bool FillBuffer()
   {
      if(m_file_handle < 0 || m_is_eof) return false;
      int remaining = m_buf_lim - m_buf_pos;
      if(remaining > 0) ArrayCopy(m_buffer, m_buffer, 0, m_buf_pos, remaining);
      m_buf_pos = 0;
      m_buf_lim = remaining;
      int bytes_to_read = ArraySize(m_buffer) - m_buf_lim;
      if (bytes_to_read <= 0)
      {
         m_is_eof = true;
         return false;
      }
      int bytes_read = (int)FileReadArray(m_file_handle, m_buffer, m_buf_lim, bytes_to_read);
      if(bytes_read <= 0)
      {
         m_is_eof = true;
         return m_buf_lim > 0;
      }
      m_buf_lim += bytes_read;
      return true;
   }

   ushort DecodeNextChar()
   {
      if (m_buf_pos >= m_buf_lim && !FillBuffer()) return 0;
      if (m_buf_pos >= m_buf_lim) return 0;
      uchar b1 = m_buffer[m_buf_pos++];
      ushort cp;
      if(b1 < 0x80)   // 1-byte
      {
         cp = b1;
      }
      else if((b1 & 0xE0) == 0xC0)     // 2-byte
      {
         if((m_buf_pos >= m_buf_lim && !FillBuffer()) || (m_buf_pos >= m_buf_lim)) return '?';
         uchar b2 = m_buffer[m_buf_pos++];
         cp = (ushort(b1 & 0x1F) << 6) | ushort(b2 & 0x3F);
      }
      else if((b1 & 0xF0) == 0xE0)     // 3-byte
      {
         if((m_buf_pos + 1 >= m_buf_lim && !FillBuffer()) || (m_buf_pos + 1 >= m_buf_lim)) return '?';
         uchar b2 = m_buffer[m_buf_pos++], b3 = m_buffer[m_buf_pos++];
         cp = (ushort(b1 & 0x0F) << 12) | (ushort(b2 & 0x3F) << 6) | ushort(b3 & 0x3F);
      }
      else     // 4-byte or invalid
      {
         cp = '?';
      }
      return cp;
   }

public:
   FileStreamReader(int handle, int buffer_size=8192) :
      m_file_handle(handle), m_buf_pos(0), m_buf_lim(0), m_line(1), m_col(1), m_is_eof(false), m_peek_char(0)
   {
      if(buffer_size <= 0) buffer_size = 8192;
      if(ArrayResize(m_buffer, buffer_size) != buffer_size) m_file_handle = -1;
   }

   bool IsEOF() const override
   {
      return m_peek_char == 0 && m_buf_pos >= m_buf_lim && m_is_eof;
   }
   int  Line() const override
   {
      return m_line;
   }
   int  Column() const override
   {
      return m_col;
   }

   ushort Peek() override
   {
      if(m_peek_char == 0 && !IsEOF()) m_peek_char = DecodeNextChar();
      return m_peek_char;
   }

   ushort Next() override
   {
      ushort c;
      if(m_peek_char != 0)
      {
         c = m_peek_char;
         m_peek_char = 0;
      }
      else
      {
         c = DecodeNextChar();
      }
      if(c == '\n')
      {
         m_line++;
         m_col = 1;
      }
      else if(c != 0)
      {
         m_col++;
      }
      return c;
   }

   bool Prev() override
   {
      // Not supported for forward-only file stream.
      // Returning false indicates failure.
      return false;
   }

   string GetContext(int length) const override
   {
      return "Context unavailable for file stream";
   }
};

} // End namespace Internal
} // End namespace MQL5_Json
#endif  // MQL5_JSON_INTERNAL_STREAM_V10_H
