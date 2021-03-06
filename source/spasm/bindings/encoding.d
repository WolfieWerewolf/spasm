module spasm.bindings.encoding;

import spasm.types;
import spasm.bindings.common;

struct TextDecodeOptions {
  JsHandle handle;
  alias handle this;
  static auto create() {
    return TextDecodeOptions(JsHandle(spasm_add__object()));
  }
  void stream(bool stream) {
    TextDecodeOptions_stream_Set(this.handle, stream);
  }
  auto stream() {
    return TextDecodeOptions_stream_Get(this.handle);
  }
}
struct TextDecoder {
  JsHandle handle;
  alias handle this;
  auto decode(BufferSource input, TextDecodeOptions options) {
    return TextDecoder_decode(this.handle, input, options.handle);
  }
  auto decode(BufferSource input) {
    return TextDecoder_decode_0(this.handle, input);
  }
  auto decode() {
    return TextDecoder_decode_1(this.handle);
  }
  auto encoding() {
    return TextDecoderCommon_encoding_Get(this.handle);
  }
  auto fatal() {
    return TextDecoderCommon_fatal_Get(this.handle);
  }
  auto ignoreBOM() {
    return TextDecoderCommon_ignoreBOM_Get(this.handle);
  }
}
struct TextDecoderOptions {
  JsHandle handle;
  alias handle this;
  static auto create() {
    return TextDecoderOptions(JsHandle(spasm_add__object()));
  }
  void fatal(bool fatal) {
    TextDecoderOptions_fatal_Set(this.handle, fatal);
  }
  auto fatal() {
    return TextDecoderOptions_fatal_Get(this.handle);
  }
  void ignoreBOM(bool ignoreBOM) {
    TextDecoderOptions_ignoreBOM_Set(this.handle, ignoreBOM);
  }
  auto ignoreBOM() {
    return TextDecoderOptions_ignoreBOM_Get(this.handle);
  }
}
struct TextDecoderStream {
  JsHandle handle;
  alias handle this;
  auto encoding() {
    return TextDecoderCommon_encoding_Get(this.handle);
  }
  auto fatal() {
    return TextDecoderCommon_fatal_Get(this.handle);
  }
  auto ignoreBOM() {
    return TextDecoderCommon_ignoreBOM_Get(this.handle);
  }
  auto readable() {
    return ReadableStream(JsHandle(GenericTransformStream_readable_Get(this.handle)));
  }
  auto writable() {
    return WritableStream(JsHandle(GenericTransformStream_writable_Get(this.handle)));
  }
}
struct TextEncoder {
  JsHandle handle;
  alias handle this;
  auto encode(string input /* = "" */) {
    return Uint8Array(JsHandle(TextEncoder_encode(this.handle, input)));
  }
  auto encode() {
    return Uint8Array(JsHandle(TextEncoder_encode_0(this.handle)));
  }
  auto encoding() {
    return TextEncoderCommon_encoding_Get(this.handle);
  }
}
struct TextEncoderStream {
  JsHandle handle;
  alias handle this;
  auto encoding() {
    return TextEncoderCommon_encoding_Get(this.handle);
  }
  auto readable() {
    return ReadableStream(JsHandle(GenericTransformStream_readable_Get(this.handle)));
  }
  auto writable() {
    return WritableStream(JsHandle(GenericTransformStream_writable_Get(this.handle)));
  }
}


extern (C) Handle GenericTransformStream_readable_Get(Handle);
extern (C) Handle GenericTransformStream_writable_Get(Handle);
extern (C) void TextDecodeOptions_stream_Set(Handle, bool);
extern (C) bool TextDecodeOptions_stream_Get(Handle);
extern (C) string TextDecoder_decode(Handle, BufferSource, Handle);
extern (C) string TextDecoder_decode_0(Handle, BufferSource);
extern (C) string TextDecoder_decode_1(Handle);
extern (C) string TextDecoderCommon_encoding_Get(Handle);
extern (C) bool TextDecoderCommon_fatal_Get(Handle);
extern (C) bool TextDecoderCommon_ignoreBOM_Get(Handle);
extern (C) void TextDecoderOptions_fatal_Set(Handle, bool);
extern (C) bool TextDecoderOptions_fatal_Get(Handle);
extern (C) void TextDecoderOptions_ignoreBOM_Set(Handle, bool);
extern (C) bool TextDecoderOptions_ignoreBOM_Get(Handle);
extern (C) Handle TextEncoder_encode(Handle, string);
extern (C) Handle TextEncoder_encode_0(Handle);
extern (C) string TextEncoderCommon_encoding_Get(Handle);