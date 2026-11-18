#pragma once
#include <cstddef>
#include <cstring>

// Независимый прототип; не является изменением NET_Packet и не подключён к игре.
// Предел задаётся вызывающей стороной; для строгой старой проверки count < 8192
// передавайте предел 8191, а не 8192. Отказ не меняет счётчик и буфер.
inline bool grm_packet_append(unsigned char* data, size_t limit, size_t& count,
                              const void* src, size_t size) {
    if (!data || (!src && size) || count > limit || size > limit - count) return false;
    if (size) std::memcpy(data + count, src, size);
    count += size;
    return true;
}
inline bool grm_packet_read(const unsigned char* data, size_t count, size_t& pos,
                            void* dst, size_t size) {
    if (!data || (!dst && size) || pos > count || size > count - pos) return false;
    if (size) std::memcpy(dst, data + pos, size);
    pos += size;
    return true;
}
