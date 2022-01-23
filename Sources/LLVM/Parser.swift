#if SWIFT_PACKAGE
import cllvm
import llvmshims
#endif
import Foundation

public final class Parser {
  
  public let context: Context
  
  public init(context: Context = .global) {
    initializeLLVM()
    self.context = context
  }
  
  public func parse(source: String) -> Module? {
    var module: LLVMModuleRef?
    let success = source.utf8CString.withUnsafeBufferPointer { buffer in
      return LLVMParse(source, source.count, context.llvm, &module)
    }
    guard success, let m = module else { return nil }
    return Module(llvm: m, context: context)
  }
}
