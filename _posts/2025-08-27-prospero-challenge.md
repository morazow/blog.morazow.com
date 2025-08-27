---
layout: post
created_at: "2025-08-27 15:37"
tags: jit codegen llvm asmjit
title: "Prospero Challenge: JIT Codegen with LLVM and AsmJit"
published: true
---

I wanted to explore and deep dive into the Just-In-Time (JIT) compilation and code generation topics. To get some hands-on experience, I was looking for a fun project and came across the [Prospero Challenge](https://www.mattkeeter.com/projects/prospero/) from [Matt Keeter](https://www.mattkeeter.com), which was a perfect fit.

The source code for my implementation is available at [morazow/prospero-rust](https://github.com/morazow/prospero-rust).

The challenge is simple, you are given list of ~8k mathematical expressions that must be evaluated for each pixel `(x, y)` in an image (e.g., 1024x1024 size). The pixel is then colored black or white based on the sign of the final result.

The input is a series of operations that build up the expression:

```
# Text of a monologue from The Tempest
_0 const 2.95
_1 var-x
_2 const 8.13008
_3 mul _1 _2
_4 add _0 _3
_5 const 3.675
# ...
```

When rendered, these expressions produce an image as following:

<img src="/files/prospero-challenge/prospero.png" alt="Prospero Output" width="400" height="400">

You can read more about the challenge and see solutions from other developers on the [Prospero site](https://www.mattkeeter.com/projects/prospero/).

## My Approach

Since this was a learning project for me rather than a pure optimization challenge, I took a multi-stage approach, starting with the simplest implementation and progressively adding different JIT backends.

### A Baseline Virtual Machine (VM)

I started by implementing a Virtual Machine (VM). This approach is straightforward and served as a baseline for verifying the correctness of the challenge.

### JIT with LLVM

For my first Just-In-Time (JIT) compilation backend, I chose the powerful and popular [`LLVM`](https://llvm.org) framework. It is a portable, cross-platform ecosystem with a mature optimization steps. LLVM also provides a rich set of intrinsic functions (e.g., `llvm.sqrt.f64` for square roots), which simplifies code generation.

To connect Rust frontend with LLVM, I used the [inkwell](https://crates.io/crates/inkwell) crate, it helped to generate LLVM Intermediate Representation (IR) from project's Abstract Syntax Tree (AST).

### Low-Level JIT with AsmJit

Next, I wanted to experiment with [`AsmJit`](https://asmjit.com). It's a lightweight C++ library designed for low-latency machine code generation, supporting `X86`, `X86_64`, and `AArch64` architectures.

This part of the project required integrating C++ code with Rust. I built a [`Foreign Function Interface`](https://doc.rust-lang.org/rust-by-example/std_misc/ffi.html) (FFI) bridge that allowed the AsmJit compiler to consume the Rust AST and generate native code.

## Conclusion

This was a fun exercise for learning the fundamentals of just-in-time compilation, and progressing from a high-level VM to low-level machine code generation.

A special thanks to Matt Keeter for creating such an inspiring challenge!

## Future Work

While I'm happy with the result, there are always more things to explore:

- **AST-level optimizations:** Implementing duplicate expression elimination before code generation.
- **AsmJit enhancements:** Adding a constant pool for the AsmJit backend (e.g., using a `.data` section) to reduce code size and improve performance.
- **Parallelism:** Parallelizing the image rendering by processing tiles in multiple threads.
- **A C++ version:** Re-implementing the project in C++ to avoid FFI in AsmJit and to directly use LLVM C++ API.
