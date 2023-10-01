//
//  MetalView.swift
//  TikzUi
//
//  Created by Mattia Marini on 24/09/23.
//


import AppKit
import MetalKit

class MetalView : NSView, CALayerDelegate{
    
    var queue : MTLCommandQueue!
    var pipelineState : MTLRenderPipelineState!
    var metalLayer : CAMetalLayer!
    var sublayer : CAMetalLayer!
    
    private var spacing : Float = 10.0
    private var xoffset : Float = 0
    private var yoffset : Float = 0
    private var width : Float = 0
    private var height : Float = 0
    
    override var acceptsFirstResponder: Bool {
        return true
    }
   
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        width = Float(bounds.width)
        height = Float(bounds.height)
    }
    
    
    override func scrollWheel(with event: NSEvent) {
        
        let oldSpacing = spacing
        self.spacing = max(spacing + Float(event.scrollingDeltaY) * 0.1, 2.0)
        
        let viewMouseX = Float(convert(event.locationInWindow, from: nil).x)
        let viewMouseY = Float(convert(event.locationInWindow, from: nil).y)
        
        let ammount = spacing/oldSpacing
        
        let predictedX = viewMouseX - (((viewMouseX - xoffset).truncatingRemainder(dividingBy:  oldSpacing))*ammount)
        self.xoffset =  predictedX.truncatingRemainder(dividingBy: spacing)
        
        let predictedY = viewMouseY - (((viewMouseY - yoffset).truncatingRemainder(dividingBy:  oldSpacing))*ammount)
        self.yoffset =  predictedY.truncatingRemainder(dividingBy: spacing)
        
        setNeedsDisplay(bounds)
    }
    
    /*
    override func mouseMoved(with event: NSEvent) {
        print("\(event.locationInWindow.x) \(event.locationInWindow.y)" )
    }
    */
    
    override func mouseMoved(with event: NSEvent) {
        print("moved")
    }
    
    override func keyUp(with event: NSEvent) {
        print(event.keyCode)
    }
    
    
    func display(_ layer: CALayer) {
        drawGrid()
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        width = Float(newSize.width)
        height = Float(newSize.height)
        // the conversion below is necessary for high DPI drawing
        metalLayer.drawableSize = convertToBacking(newSize)
        self.viewDidChangeBackingProperties()
    }
    
    override func viewDidChangeBackingProperties() {
        guard let window = self.window else { return }
        // This is necessary to render correctly on retina displays with the topLeft placement policy
        metalLayer.contentsScale = window.backingScaleFactor
    }
   
    private func drawLines(){
        let drawable = sublayer.nextDrawable()!
        
        let passDescriptor = MTLRenderPassDescriptor()
        let colorAttachment = passDescriptor.colorAttachments[0]!
        colorAttachment.texture = drawable.texture
        colorAttachment.loadAction = .clear
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
        
        guard   let commandBuffer = queue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else{
            print("errore di rendering")
            return
        }
        
        let infos = [width, height, xoffset, yoffset, spacing]
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBytes(infos, length: MemoryLayout<Float>.size * infos.count, index: 0)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: Int( (floor((infos[0] - xoffset) / spacing)+1) * (floor((infos[1] - yoffset) / spacing)+1)))
      
        
        renderEncoder.endEncoding()
       
        
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        
        drawable.present()
    }
    
    private func drawGrid(){
        
              
        let drawable = metalLayer.nextDrawable()!
        
        let passDescriptor = MTLRenderPassDescriptor()
        let colorAttachment = passDescriptor.colorAttachments[0]!
        colorAttachment.texture = drawable.texture
        colorAttachment.loadAction = .clear
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
        
        guard   let commandBuffer = queue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else{
            print("errore di rendering")
            return
        }
        
        let infos = [width, height, xoffset, yoffset, spacing]
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBytes(infos, length: MemoryLayout<Float>.size * infos.count, index: 0)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: Int( (floor((infos[0] - xoffset) / spacing)+1) * (floor((infos[1] - yoffset) / spacing)+1)))
      
        
        renderEncoder.endEncoding()
       
        
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        
        drawable.present()
    }
    
    private func makePipeline() {
        
        guard let library = metalLayer.device?.makeDefaultLibrary() else {print("errore makePipeline"); return}
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = library.makeFunction(name: "vertex_function")
        pipelineStateDescriptor.fragmentFunction = library.makeFunction(name: "fragment_function")
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try metalLayer.device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        catch let error as NSError{
            print("Errore nella creazione della pipeline")
            print(error)
        }
        
    }
    
    override func makeBackingLayer() -> CALayer {
                
        
        metalLayer = CAMetalLayer()
        sublayer = CAMetalLayer()
        metalLayer.addSublayer(sublayer)
        
        metalLayer.delegate = self
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.device = MTLCreateSystemDefaultDevice()
        
        queue = metalLayer.device?.makeCommandQueue()
        
        metalLayer.allowsNextDrawableTimeout = false
        
        // these properties are crucial to resizing working
        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
        
        makePipeline()
        
        return metalLayer
    }
    
}

class MyLayer : CAMetalLayer {
    override func display() {
    }
    
}

/*
override func draw(_ dirtyRect: NSRect) {
        drawGrid()
    }
    
    private func drawGrid(){
        
             
        let drawable = metalLayer.nextDrawable()!
        
        let passDescriptor = MTLRenderPassDescriptor()
        let colorAttachment = passDescriptor.colorAttachments[0]!
        colorAttachment.texture = drawable.texture
        colorAttachment.loadAction = .clear
        colorAttachment.storeAction = .store
        colorAttachment.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        guard   let commandBuffer = queue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else{
            print("errore di rendering")
            return
        }
        
        let infos = [Float(bounds.width), Float(bounds.height), xoffset, yoffset, spacing]
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBytes(infos, length: MemoryLayout<Float>.size * infos.count, index: 0)
        
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1, instanceCount: Int( (floor((infos[0] - xoffset) / spacing)+1) * (floor((infos[1] - yoffset) / spacing)+1)))
      
        
        renderEncoder.endEncoding()
       
        
        //commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilScheduled()
        //commandBuffer.waitUntilCompleted()
        
        drawable.present()
    }
    

 */
