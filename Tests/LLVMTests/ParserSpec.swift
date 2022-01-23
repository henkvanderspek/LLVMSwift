import LLVM
import XCTest
import Foundation

class ParserSpec : XCTestCase {
  func testParser() {
    let s = """
      define i32 @mul_add(i32 %x, i32 %y, i32 %z) {
      entry:
        %tmp = mul i32 %x, %y
        %tmp2 = add i32 %tmp, %z
        ret i32 %tmp2
      }
    """
    let p = Parser()
    let m = p.parse(source: s)
    XCTAssertNotNil(m)
    XCTAssertNoThrow(try m!.verify())
  }
}
