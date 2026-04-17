#!/usr/bin/env swift
//
// Crop a PNG to a rect (x, y, w, h) in pixels. Top-left origin.
// usage: crop-png.swift SRC DST X Y W H
//

import AppKit

let args = CommandLine.arguments
guard args.count == 7 else {
    FileHandle.standardError.write("usage: crop-png.swift SRC DST X Y W H\n".data(using: .utf8)!)
    exit(2)
}

let src = URL(fileURLWithPath: args[1])
let dst = URL(fileURLWithPath: args[2])
guard let x = Int(args[3]), let y = Int(args[4]),
      let w = Int(args[5]), let h = Int(args[6]) else {
    FileHandle.standardError.write("numeric args required\n".data(using: .utf8)!)
    exit(2)
}

guard let data = try? Data(contentsOf: src),
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    FileHandle.standardError.write("could not load image: \(src.path)\n".data(using: .utf8)!)
    exit(1)
}

let rect = CGRect(x: x, y: y, width: w, height: h)
guard let cropped = cg.cropping(to: rect) else {
    FileHandle.standardError.write("crop failed (rect out of bounds?)\n".data(using: .utf8)!)
    exit(1)
}

let rep = NSBitmapImageRep(cgImage: cropped)
guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("png encode failed\n".data(using: .utf8)!)
    exit(1)
}

try png.write(to: dst)
