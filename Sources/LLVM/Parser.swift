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
  
  public func parse(source: String, name: String) -> Module {
    let buffer = source.utf8CString.withUnsafeBufferPointer { $0 }
    let buf = MemoryBuffer(buffer: buffer, name: UUID().uuidString).llvm
    let mod = Module(name: name, context: context)
    var module: LLVMModuleRef? = mod.llvm
    var message: UnsafeMutablePointer<Int8>?
    LLVMParseIRInContext(context.llvm, buf, &module, &message)
    return mod
  }
}
