#!/usr/bin/env swift
// Renders rCodexPDF's app icon at 1024x1024 as a PNG using Core Graphics — no external image
// assets or design tools required. Run once; the output is committed to Resources/Assets and
// consumed by Scripts/build-app.sh via `iconutil`.

import AppKit
import CoreGraphics

let size = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

guard let context = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create CGContext")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

// Background: rounded-square with a blue-to-purple gradient, matching macOS "squircle" icon style.
let cornerRadius: CGFloat = CGFloat(size) * 0.225
let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.42, blue: 0.93, alpha: 1.0),
    NSColor(calibratedRed: 0.52, green: 0.18, blue: 0.86, alpha: 1.0)
])!
gradient.draw(in: backgroundPath, angle: -60)

// Document/page shape (white, slightly rotated) representing the PDF viewer.
let pageWidth = CGFloat(size) * 0.34
let pageHeight = CGFloat(size) * 0.46
let pageRect = CGRect(
    x: CGFloat(size) * 0.30 - pageWidth / 2,
    y: CGFloat(size) * 0.50 - pageHeight / 2,
    width: pageWidth, height: pageHeight
)
let pagePath = NSBezierPath(roundedRect: pageRect, xRadius: pageWidth * 0.08, yRadius: pageWidth * 0.08)
NSColor.white.withAlphaComponent(0.95).setFill()
pagePath.fill()

// Text lines on the page.
NSColor(calibratedWhite: 0.2, alpha: 0.55).setFill()
let lineHeight = pageHeight * 0.045
for i in 0..<6 {
    let y = pageRect.maxY - pageHeight * 0.22 - CGFloat(i) * lineHeight * 1.8
    let inset = pageWidth * 0.14
    let width = i % 3 == 2 ? pageWidth * 0.4 : pageWidth - inset * 2
    let lineRect = CGRect(x: pageRect.minX + inset, y: y, width: width, height: lineHeight)
    NSBezierPath(roundedRect: lineRect, xRadius: lineHeight / 2, yRadius: lineHeight / 2).fill()
}

// Code brackets "</>" representing the code editor, on the right side.
let bracketFont = NSFont.monospacedSystemFont(ofSize: CGFloat(size) * 0.20, weight: .bold)
let bracketAttrs: [NSAttributedString.Key: Any] = [
    .font: bracketFont,
    .foregroundColor: NSColor.white
]
let bracketString = NSAttributedString(string: "</>", attributes: bracketAttrs)
let bracketSize = bracketString.size()
let bracketOrigin = CGPoint(
    x: CGFloat(size) * 0.66 - bracketSize.width / 2,
    y: CGFloat(size) * 0.30 - bracketSize.height / 2
)
bracketString.draw(at: bracketOrigin)

// Chat bubble representing the AI assistant, upper right.
let bubbleRect = CGRect(x: CGFloat(size) * 0.60, y: CGFloat(size) * 0.62, width: CGFloat(size) * 0.28, height: CGFloat(size) * 0.20)
let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: bubbleRect.height * 0.35, yRadius: bubbleRect.height * 0.35)
NSColor.white.withAlphaComponent(0.95).setFill()
bubblePath.fill()
let tail = NSBezierPath()
tail.move(to: CGPoint(x: bubbleRect.minX + bubbleRect.width * 0.25, y: bubbleRect.minY))
tail.line(to: CGPoint(x: bubbleRect.minX + bubbleRect.width * 0.10, y: bubbleRect.minY - bubbleRect.height * 0.28))
tail.line(to: CGPoint(x: bubbleRect.minX + bubbleRect.width * 0.42, y: bubbleRect.minY))
tail.close()
NSColor.white.withAlphaComponent(0.95).setFill()
tail.fill()
NSColor(calibratedRed: 0.16, green: 0.42, blue: 0.93, alpha: 1.0).setFill()
for i in 0..<3 {
    let dotSize = bubbleRect.height * 0.14
    let spacing = bubbleRect.width * 0.22
    let dotRect = CGRect(
        x: bubbleRect.midX - spacing + CGFloat(i) * spacing - dotSize / 2,
        y: bubbleRect.midY - dotSize / 2,
        width: dotSize, height: dotSize
    )
    NSBezierPath(ovalIn: dotRect).fill()
}

NSGraphicsContext.restoreGraphicsState()

guard let cgImage = context.makeImage() else { fatalError("Could not create CGImage") }
let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
