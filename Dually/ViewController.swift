//
//  ViewController.swift
//  Second Screen Web App
//
//  Created by Jeremy Bueler on 6/30/14.
//	Copyright (c) 2014 Roundhouse Agency
//
//	[The MIT License (MIT)](http://opensource.org/licenses/MIT)
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import UIKit

class ViewController: UIViewController, UIPopoverControllerDelegate, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet var toolbar: UIToolbar
	@IBOutlet var primaryWebview: UIWebView
	@IBOutlet var secondaryWebview: UIWebView
	@IBOutlet var resolutionBarButton: UIBarButtonItem
	@IBOutlet var secondScreenRefreshButton: UIBarButtonItem

	@lazy var secondWindow = UIWindow()

	var popoverMenu:UIPopoverController?
	var secondScreen:UIScreen?
	var primary_screen_address:String = ""
	var second_screen_address:String = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		disableCache()
	}
	
	override func viewDidAppear(animated: Bool) {
		subscribeToSecondScreenNotifications()
		screenDidChange(nil)
		getDefaults()
		primaryWebview.scrollView.delaysContentTouches = false
		primaryWebview.scrollView.bounces = false
		primaryWebview.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
		
		loadWebAddress(primary_screen_address, webview: primaryWebview)
		loadWebAddress(second_screen_address, webview: secondaryWebview)
	}

	override func viewDidDisappear(animated: Bool) {
		unsubscribeToSecondScreenNotifications()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		println("Memory warning recieved")
	}
	
	func getDefaults(){
		let options = NSUserDefaults.standardUserDefaults()

		/* ***********************************
			Change the value of defaultUrl (defined below) if you want to set a different default URL
		*********************************** */
		let defaultUrl = "http://roundhouseagency.com"
		
		if let primaryAddress = options.stringForKey("primary_screen_url"){
			primary_screen_address = primaryAddress
		}
		else{
			// TODO: THIS IS JUST A BACKUP URL
			primary_screen_address = defaultUrl
		}

		if let secondaryAddress = options.stringForKey("second_screen_url"){
			second_screen_address = secondaryAddress
		}
		else{
			second_screen_address = defaultUrl
		}
	}

	func subscribeToSecondScreenNotifications(){
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "appIsActive", name: UIApplicationDidBecomeActiveNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "screenDidChange:", name: UIScreenDidConnectNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "screenDidChange:", name: UIScreenDidDisconnectNotification, object: nil)
	}
	
	func unsubscribeToSecondScreenNotifications(){
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIScreenDidDisconnectNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIScreenDidConnectNotification, object: nil)
	}
	
	func appIsActive(){
		var currentPrimaryAddress = primary_screen_address
		var currentSecondaryAddress = second_screen_address
		
		getDefaults()
		
		if currentPrimaryAddress != primary_screen_address{
			loadWebAddress(primary_screen_address, webview: primaryWebview)
		}
		
		if currentSecondaryAddress != second_screen_address{
			loadWebAddress(second_screen_address, webview: secondaryWebview)
		}
		
	}

	func screenDidChange(notification: NSNotification?){
		var screens = UIScreen.screens()

		if screens.count > 1{
			self.secondScreen = (screens[1] as UIScreen)

			if let screen = self.secondScreen{
				setupSecondScreen(screen)
			}
		}
		else{
			resolutionBarButton.title = "Screen Not Detected"
			resolutionBarButton.enabled = false
			secondScreenRefreshButton.enabled = false
			secondScreen = nil
		}
	}
	
	func setupSecondScreen(screen:UIScreen){
		var availableModes = screen.availableModes
		var lastMode = availableModes[availableModes.count - 1] as UIScreenMode
		screen.currentMode = lastMode
		screen.overscanCompensation = UIScreenOverscanCompensation.InsetApplicationFrame
		resolutionBarButton.title = "\(Int(lastMode.size.width))x\(Int(lastMode.size.height))"
		resolutionBarButton.enabled = true
		secondScreenRefreshButton.enabled = true

		secondWindow.frame = screen.bounds
		secondWindow.screen = screen
		secondaryWebview.frame = secondWindow.frame
		secondWindow.addSubview(self.secondaryWebview)
		secondWindow.makeKeyAndVisible()
		primaryWebview.window.makeKeyWindow()
	}

	func loadWebAddress(address:String, webview: UIWebView){
		var url = NSURL(string: address)
		var request = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 0)
		webview.loadRequest(request)
	}
	
	@IBAction func showResolutionMenu(sender: AnyObject) {
		// create table view controller
		var resolutionTable = UITableViewController(style: UITableViewStyle.Plain)

		// create the table view
		resolutionTable.tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 500))
		
		// setup tableview delegates
		resolutionTable.tableView.delegate = self
		resolutionTable.tableView.dataSource = self

		// set the reuse identifier for the tableViewCell
		resolutionTable.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

		if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
			// create popover controller
			popoverMenu = UIPopoverController(contentViewController: resolutionTable)
			
			// display popover ui from the UIbarButtonItem sender
			popoverMenu!.presentPopoverFromBarButtonItem(sender as UIBarButtonItem, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
		}
		else{
			self.presentViewController(resolutionTable, animated: true, completion: nil)
		}
	}
	
	@IBAction func refreshPrimary(sender: AnyObject) {
		getDefaults()
		disableCache()
		loadWebAddress(primary_screen_address, webview: primaryWebview)
	}

	@IBAction func refreshSecondary(sender: AnyObject) {
		getDefaults()
		disableCache()
		loadWebAddress(second_screen_address, webview: secondaryWebview)
	}
	
	func disableCache(){
		NSURLCache.sharedURLCache().removeAllCachedResponses()
		NSURLCache.sharedURLCache().diskCapacity = 0
		NSURLCache.sharedURLCache().memoryCapacity = 0
	}

	//	TABLE VIEW METHODS
	// #pragma mark - Table View
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var count = 0
		if let screen = secondScreen{
			count = screen.availableModes.count
		}
		return count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
		var availableModes = []
		if let screen = secondScreen{
			availableModes = screen.availableModes
		}
		var currentMode: UIScreenMode =  availableModes.objectAtIndex(indexPath.item) as UIScreenMode
		cell.textLabel.text = "\(Int(currentMode.size.width))x\(Int(currentMode.size.height))"
		return cell
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		// Return true if you want the specified item to be editable.
		return false
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		if let screen = secondScreen{
			var availableModes = []
			availableModes = screen.availableModes
			screen.currentMode = availableModes.objectAtIndex(indexPath.item) as UIScreenMode

			if let popover = popoverMenu{
				popover.dismissPopoverAnimated(true)
			}
			else{
				self.dismissViewControllerAnimated(true, completion: nil)
			}

		}
	}
	

}

