#if SWIFT_PACKAGE
import cllvm
import llvmshims
#endif
import Foundation

public final class Parser {
  
  public let context: Context
  
  public init(context: Context = .global) {
    self.context = context
  }
  
  public func parse(source: String, name: String) -> Module? {
    return source.utf8CString.withUnsafeBufferPointer { buffer in
      let buf = MemoryBuffer(buffer: buffer, name: UUID().uuidString).llvm
      let mod = Module(name: name, context: context)
      var module: LLVMModuleRef? = mod.llvm
      var message: UnsafeMutablePointer<Int8>?
      LLVMParseIRInContext(context.llvm, buf, &module, &message)
      return mod
    }
  }
}
