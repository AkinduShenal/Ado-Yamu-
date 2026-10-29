import AppKit
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let background = NSBezierPath(rect: NSRect(origin: .zero, size: size))
NSGradient(colors: [NSColor(red: 0.31, green: 0.14, blue: 0.85, alpha: 1), NSColor(red: 0.59, green: 0.38, blue: 1, alpha: 1)])?.draw(in: background, angle: 55)
let glow = NSBezierPath(ovalIn: NSRect(x: 430, y: 460, width: 650, height: 650))
NSColor.white.withAlphaComponent(0.08).setFill(); glow.fill()
let map = NSBezierPath(); map.move(to: NSPoint(x: 185, y: 220)); map.line(to: NSPoint(x: 380, y: 170)); map.line(to: NSPoint(x: 610, y: 240)); map.line(to: NSPoint(x: 835, y: 185)); map.line(to: NSPoint(x: 790, y: 590)); map.line(to: NSPoint(x: 610, y: 640)); map.line(to: NSPoint(x: 390, y: 570)); map.line(to: NSPoint(x: 230, y: 620)); map.close()
NSColor(red: 1, green: 0.92, blue: 0.73, alpha: 1).setFill(); map.fill()
let fold = NSBezierPath(); fold.move(to:NSPoint(x:380,y:170)); fold.line(to:NSPoint(x:390,y:570)); fold.move(to:NSPoint(x:610,y:240)); fold.line(to:NSPoint(x:610,y:640)); fold.lineWidth = 14
NSColor(red: 0.88, green: 0.74, blue: 0.48, alpha: 0.5).setStroke(); fold.stroke()
let trail = NSBezierPath(); trail.move(to: NSPoint(x: 280, y: 310)); trail.curve(to: NSPoint(x: 690,y: 390), controlPoint1: NSPoint(x: 420,y: 500), controlPoint2:NSPoint(x: 560,y: 210)); trail.lineWidth = 18; trail.lineCapStyle = .round; trail.setLineDash([16,25], count: 2, phase: 0)
NSColor(red: 0.84, green: 0.42, blue: 0.13, alpha: 0.8).setStroke(); trail.stroke()
let pin = NSBezierPath(); pin.move(to:NSPoint(x:515,y:370)); pin.curve(to:NSPoint(x:330,y:680),controlPoint1:NSPoint(x:465,y:440),controlPoint2:NSPoint(x:330,y:580)); pin.curve(to:NSPoint(x:700,y:680),controlPoint1:NSPoint(x:330,y:940),controlPoint2:NSPoint(x:700,y:940)); pin.curve(to:NSPoint(x:515,y:370),controlPoint1:NSPoint(x:700,y:580),controlPoint2:NSPoint(x:565,y:440)); pin.close()
NSGradient(colors:[NSColor(red:1,green:0.53,blue:0.20,alpha:1),NSColor(red:1,green:0.75,blue:0.38,alpha:1)])?.draw(in:pin,angle:90)
NSColor(red: 0.30, green: 0.14, blue: 0.66, alpha: 1).setFill(); NSBezierPath(ovalIn:NSRect(x:443,y:625,width:144,height:144)).fill()
image.unlockFocus()
if let tiff=image.tiffRepresentation, let bitmap=NSBitmapImageRep(data:tiff), let data=bitmap.representation(using:.png,properties:[:]) { try data.write(to:URL(fileURLWithPath:CommandLine.arguments[1])) }
