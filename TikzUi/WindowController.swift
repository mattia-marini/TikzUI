//
//  WindowController.swift
//  TikzUi
//
//  Created by Mattia Marini on 27/09/23.
//

import AppKit

class WindowController : NSWindowController{
    
    
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet var pencil: NSToolbarItem!
    @IBAction func draw(_ sender: NSToolbarItem) {
        print("draw")
    }
    
    
    @IBAction func eraser(_ sender: NSToolbarItem) {
        print("erase")
    }
    @IBAction func select(_ sender: NSToolbarItem) {
        print("select")
    }
    @IBAction func convert(_ sender: NSToolbarItem) {
        print("convert")
    }
    override func windowDidLoad() {
    }
}
