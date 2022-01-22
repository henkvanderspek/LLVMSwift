//
//  jitApp.swift
//  jit
//
//  Created by Henk van der Spek on 21/01/2022.
//

import SwiftUI
import LLVM

@main
struct jitApp: App {
    var body: some Scene {
        WindowGroup {
            let _ = run()
            ContentView()
        }
    }
}

@_cdecl("_print")
func print()->Int64 {
    print("Test")
    return 20
}

private extension jitApp {
    func run() {
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        let m = Module(name: "main")
        let b = IRBuilder(module: m)
        let main = b.addFunction("main", type: .init([], IntType.int64))
        let e = main.appendBasicBlock(named: "entry")
        b.positionAtEnd(of: e)
        let type = b.createStruct(name: "DataType", types: [IntType.int64, IntType.int64], isPacked: false)
        let mem = b.buildAlloca(type: type)
        let field0 = b.buildInBoundsGEP(mem, type: type, indices: [
            IntType.int32.constant(0),
            IntType.int32.constant(0)
        ])
        let field1 = b.buildInBoundsGEP(mem, type: type, indices: [
            IntType.int32.constant(0),
            IntType.int32.constant(1)
        ])
        b.buildStore(IntType.int64.constant(20), to: field0)
        let val0 = b.buildLoad(field0, type: IntType.int64)
        b.buildStore(IntType.int64.constant(10), to: field1)
        let val1 = b.buildLoad(field1, type: IntType.int64)
        let pr = b.addFunction("print", type: .init([], IntType.int64))
        let r = b.buildCall(pr, args: [])
        // This would cause an infinite loop and stack overflow
        // let _ = b.buildCall(main, args: [])
        let total = b.buildAdd(val0, val1)
        let c = IntType.int64.constant(20)
        let s = b.buildAdd(r, c)
        let ret = b.buildAdd(s, total)
        b.buildRet(ret)

        do {
            let jit = try JIT(machine: TargetMachine())
            
            _ = try jit.addEagerlyCompiledIR(m) { (name) -> JIT.TargetAddress in
                let sym = dlsym(RTLD_DEFAULT, name)
                let a = UInt64(bitPattern: Int64(Int(bitPattern: sym)))
                return a != 0 ? .init(raw: a) : .init()
            }
            
            typealias FnPtr = @convention(c) ()->Int64
            
            let addr = try jit.address(of: "main")
            let fn = unsafeBitCast(addr, to: FnPtr.self)
            
            print(fn())
        } catch {
            print(error)
        }
    }
}
