//+------------------------------------------------------------------+
//|  Core/JsonUtils.mqh                                              |
//+------------------------------------------------------------------+

#ifndef MQL5_JSON_INTERNAL_UTILS_V10_H
#define MQL5_JSON_INTERNAL_UTILS_V10_H

#include "JsonCore.mqh"

namespace MQL5_Json
{
namespace Internal
{

long JsonHexToInteger(const string h)
{
   long result = 0;
   const int len = StringLen(h);
   for(int i = 0; i < len; i++)
   {
      result <<= 4; // Shift result left by 4 bits to make space for the new nibble
      ushort c = StringGetCharacter(h, i);
      if(c >= '0' && c <= '9')      result |= (c - '0');
      else if(c >= 'a' && c <= 'f') result |= (c - 'a' + 10);
      else if(c >= 'A' && c <= 'F') result |= (c - 'A' + 10);
   }
   return result;
}


// --- OPTIMIZED IMPLEMENTATION ---
// This function uses a two-pass approach to avoid repeated ArrayResize calls,
// significantly improving performance for large strings.
bool JsonStringToUtf8Bytes(const string &s, uchar &out_bytes[], bool write_bom)
{
   ArrayFree(out_bytes);
   ushort shorts[];
   int len = StringToShortArray(s, shorts);
// --- Pass 1: Calculate the exact buffer size needed ---
   int total_bytes_needed = 0;
   if(write_bom)
   {
      total_bytes_needed = 3;
   }
   for(int i = 0; i < len; i++)
   {
      ulong cp = shorts[i];
      // Handle surrogate pairs
      if (cp >= 0xD800 && cp <= 0xDBFF && (i + 1 < len))
      {
         ushort next_char = shorts[i+1];
         if (next_char >= 0xDC00 && next_char <= 0xDFFF)
         {
            cp = 0x10000 + ((cp - 0xD800) << 10) | (next_char - 0xDC00);
            i++; // Skip the low surrogate in the next iteration
         }
      }
      if(cp < 0x80)       total_bytes_needed += 1;
      else if(cp < 0x800)  total_bytes_needed += 2;
      else if(cp < 0x10000)total_bytes_needed += 3;
      else                 total_bytes_needed += 4;
   }
// --- Single Memory Allocation ---
   if(total_bytes_needed == 0)
   {
      return true; // Return empty array for empty string
   }
   if(ArrayResize(out_bytes, total_bytes_needed) < 0)
   {
      // Failed to allocate memory
      ArrayFree(out_bytes);
      return false;
   }
// --- Pass 2: Fill the pre-allocated buffer ---
   int write_pos = 0;
   if(write_bom)
   {
      out_bytes[0] = 0xEF;
      out_bytes[1] = 0xBB;
      out_bytes[2] = 0xBF;
      write_pos = 3;
   }
   for(int i = 0; i < len; i++)
   {
      ulong cp = shorts[i];
      // Re-evaluate surrogate pairs (logic must be identical to pass 1)
      if (cp >= 0xD800 && cp <= 0xDBFF && (i + 1 < len))
      {
         ushort next_char = shorts[i+1];
         if (next_char >= 0xDC00 && next_char <= 0xDFFF)
         {
            cp = 0x10000 + ((cp - 0xD800) << 10) | (next_char - 0xDC00);
            i++;
         }
      }
      if(cp < 0x80) // 1-byte sequence
      {
         out_bytes[write_pos++] = (uchar)cp;
      }
      else if(cp < 0x800) // 2-byte sequence
      {
         out_bytes[write_pos++] = (uchar)(0xC0 | (cp >> 6));
         out_bytes[write_pos++] = (uchar)(0x80 | (cp & 0x3F));
      }
      else if(cp < 0x10000) // 3-byte sequence
      {
         out_bytes[write_pos++] = (uchar)(0xE0 | (cp >> 12));
         out_bytes[write_pos++] = (uchar)(0x80 | ((cp >> 6) & 0x3F));
         out_bytes[write_pos++] = (uchar)(0x80 | (cp & 0x3F));
      }
      else // 4-byte sequence
      {
         out_bytes[write_pos++] = (uchar)(0xF0 | (cp >> 18));
         out_bytes[write_pos++] = (uchar)(0x80 | ((cp >> 12) & 0x3F));
         out_bytes[write_pos++] = (uchar)(0x80 | ((cp >> 6) & 0x3F));
         out_bytes[write_pos++] = (uchar)(0x80 | (cp & 0x3F));
      }
   }
   return true;
}


} // End namespace Internal
} // End namespace MQL5_Json
#endif // MQL5_JSON_INTERNAL_UTILS_V10_H
