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

private extension jitApp {
    func run() {
        let m = Module(name: "main")
        let b = IRBuilder(module: m)
        let main = b.addFunction("main", type: .init([], IntType.int64))
        let e = main.appendBasicBlock(named: "entry")
        b.positionAtEnd(of: e)
        let foo = b.addFunction("foo", type: .init([], IntType.int64))
        let r = b.buildCall(foo, args: [])
        // This would cause an infinite loop and stack overflow
        // let _ = b.buildCall(main, args: [])
        let c = IntType.int64.constant(21)
        let s = b.buildAdd(r, c)
        b.buildRet(s)

        do {
            let jit = try JIT(machine: TargetMachine())
            
            _ = try jit.addEagerlyCompiledIR(m) { (name) -> JIT.TargetAddress in
                switch name {
                case "_foo":
                    typealias FooPtr = @convention(c) ()->Int64
                    let f: FooPtr = {
                        print("bar")
                        return 100
                    }
                    let p: UnsafeRawPointer? =  unsafeBitCast(f, to: UnsafeRawPointer.self)
                    let a = UInt64(bitPattern: Int64(Int(bitPattern: p)))
                    return .init(raw: a)
                default:
                    return JIT.TargetAddress()
                }
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
