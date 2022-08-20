import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar = NSStatusBar.system
    var statusBarItem: NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()

    var statusMenuItem: NSMenuItem = NSMenuItem()
    var openLogsMenuItem: NSMenuItem = NSMenuItem()
    var openCqlshMenuItem: NSMenuItem = NSMenuItem()
    var aboutMenuItem: NSMenuItem = NSMenuItem()
    var versionMenuItem: NSMenuItem = NSMenuItem()
    var quitMenuItem: NSMenuItem = NSMenuItem()

    override init() {
        super.init()
    }

    func startServer() {
        let process = Process()
        if let path = Bundle.main.path(forResource: "cassandra", ofType: "", inDirectory: "Vendor/bin") {
            process.launchPath = path
        }
        process.arguments = ["-f"]
        process.launch()
    }

    func stopServer() {
        let process = Process()
        process.arguments = ["-c", "kill -9 $(lsof -t -i:9042)"]
        process.launchPath = "/bin/bash"
        process.launch()
    }

    @objc func openCqlsh(_ send: AnyObject) {
        if let path = Bundle.main.path(forResource: "cqlsh", ofType: "", inDirectory: "Vendor/bin") {
            let task = Process()
            task.arguments = ["-b", "com.apple.terminal", path];
            task.launchPath = "/usr/bin/open"
            task.launch()
        }
    }

    @objc func openLogsDirectory(_ send: AnyObject) {
        if let path = Bundle.main.path(forResource: "debug.log", ofType: "", inDirectory: "Vendor/logs") {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    func setupSystemMenuItem() {
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        //let icon = NSImage(named: NSImage.Name(rawValue: "logo"))
        //icon!.isTemplate = true
        //statusBarItem.image = icon
        statusBarItem.title = "C"

        versionMenuItem.title = "Apache Cassandra"
        versionMenuItem.title = "Apache Cassandra v4.0.5"
        menu.addItem(versionMenuItem)
        statusMenuItem.title = "Running on Port 9042"
        menu.addItem(statusMenuItem)

        openLogsMenuItem.title = "Open logs folder"
        openLogsMenuItem.action = #selector(AppDelegate.openLogsDirectory(_:))
        menu.addItem(openLogsMenuItem)

        openCqlshMenuItem.title = "Open cqlsh"
        openCqlshMenuItem.action = #selector(AppDelegate.openCqlsh(_:))
        menu.addItem(openCqlshMenuItem)

        aboutMenuItem.title = "About"
        aboutMenuItem.action = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        menu.addItem(aboutMenuItem)


        quitMenuItem.title = "Quit"
        quitMenuItem.action = #selector(NSApplication.shared.terminate)
        menu.addItem(quitMenuItem)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupSystemMenuItem()
        startServer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopServer()
    }

}
