// File is autogenerated with `dub spasm:webidl -- --bindgen`
import {spasm as spa, encoders as encoder, decoders as decoder} from '../modules/spasm.js';
let spasm = spa;
const setBool = (ptr, val) => (spasm.heapi32u[ptr/4] = +val),
      setInt = (ptr, val) => (spasm.heapi32s[ptr/4] = val),
      setUInt = (ptr, val) => (spasm.heapi32u[ptr/4] = val),
      setShort = (ptr, val) => (spasm.heapi16s[ptr/2] = val),
      setUShort = (ptr, val) => (spasm.heapi16u[ptr/2] = val),
      setByte = (ptr, val) => (spasm.heapi8s[ptr] = val),
      setUByte = (ptr, val) => (spasm.heapi8u[ptr] = val),
      setFloat = (ptr, val) => (spasm.heapf32[ptr/4] = val),
      setDouble = (ptr, val) => (spasm.heapf64[ptr/8] = val),
      getBool = (ptr) => spasm.heapi32u[ptr/4],
      getInt = (ptr) => spasm.heapi32s[ptr/4],
      getUInt = (ptr) => spasm.heapi32u[ptr/4],
      getShort = (ptr) => spasm.heapi16s[ptr/2],
      getUShort = (ptr) => spasm.heapi16u[ptr/2],
      getByte = (ptr) => spasm.heapi8s[ptr],
      getUByte = (ptr) => spasm.heapi8u[ptr],
      getFloat = (ptr) => spasm.heapf32[ptr/4],
      getDouble = (ptr) => spasm.heapf64[ptr/8],
      isDefined = (val) => (val != undefined && val != null),
      encode_handle = (ptr, val) => { setUInt(ptr, spasm.addObject(val)); },
      decode_handle = (ptr) => { return spasm.objects[getUInt(ptr)]; },
      spasm_encode_string = encoder.string,
      spasm_decode_string = decoder.string,
      spasm_indirect_function_get = (ptr)=>spasm.instance.exports.__indirect_function_table.get(ptr);
const spasm_encode_Handle = encode_handle,
  spasm_encode_optional_Handle = (ptr, val)=>{
    if (setBool(ptr+4, isDefined(val))) {
      spasm_encode_Handle(ptr, val);
    }
  },
  spasm_decode_Handle = decode_handle,
  spasm_decode_RequestInfo = (ptr)=>{
    return spasm_decode_union2_Request_string(ptr);
  },
  spasm_decode_union2_Request_string = (ptr)=>{
    if (getUInt(ptr) == 0) {
      return spasm_decode_Handle(ptr+4);
    } else if (getUInt(ptr) == 1) {
      return spasm_decode_string(ptr+4);
    }
  };
export let jsExports = {
  Body_text: (ctx) => {
    return spasm.addObject(spasm.objects[ctx].text());
  },
  NonElementParentNode_getElementById: (rawResult, ctx, elementIdLen, elementIdPtr) => {
    spasm_encode_optional_Handle(rawResult, spasm.objects[ctx].getElementById(spasm_decode_string(elementIdLen, elementIdPtr)));
  },
  WindowOrWorkerGlobalScope_fetch_0: (ctx, input) => {
    return spasm.addObject(spasm.objects[ctx].fetch(spasm_decode_RequestInfo(input)));
  },
  console_log: (data) => {
    console.log(spasm.objects[data]);
  },
  promise_then_6uhandlehandle: (handle, ctx, ptr) => {
    return spasm.addObject(spasm.objects[handle].then((r)=>{
      encode_handle(0,r);
      spasm_indirect_function_get(ptr)(512, ctx, 0);
      return decode_handle(512);
    }));
  },
  promise_then_6uhandlev: (handle, ctx, ptr) => {
    return spasm.addObject(spasm.objects[handle].then((r)=>{
      encode_handle(0,r);
      spasm_indirect_function_get(ptr)(ctx, 0);
    }));
  },
}