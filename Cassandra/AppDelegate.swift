import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar = NSStatusBar.system
    var statusBarItem: NSStatusItem = .init()
    var menu: NSMenu = .init()

    var statusMenuItem: NSMenuItem = .init()
    var openLogsMenuItem: NSMenuItem = .init()
    var openCqlshMenuItem: NSMenuItem = .init()
    var aboutMenuItem: NSMenuItem = .init()
    var versionMenuItem: NSMenuItem = .init()
    var quitMenuItem: NSMenuItem = .init()

    override init() {
        super.init()
    }

    func askForJavaHomeAndStartServer() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Enter JAVA_HOME Path"
            alert.informativeText = "Please enter the path to your JAVA_HOME to start Cassandra :"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            inputTextField.placeholderString = "/path/to/java/home"
            alert.accessoryView = inputTextField

            if let window = alert.window as? NSPanel {
                window.becomesKeyOnlyIfNeeded = true
                window.level = .modalPanel
            }

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let javaHomePath = inputTextField.stringValue
                UserDefaults.standard.set(javaHomePath, forKey: "JavaHomePath")
                self.setupSystemMenuItem(javaHomePath: javaHomePath)
                self.startServer(javaHomePath: javaHomePath)
            }
        }
    }

    func startServer(javaHomePath: String) {
        let process = Process()
        let env = ProcessInfo.processInfo.environment
        process.environment = env.merging(["JAVA_HOME": javaHomePath]) { _, new in new }

        if let path = Bundle.main.path(forResource: "cassandra", ofType: "", inDirectory: "App/bin") {
            process.launchPath = path
        }
        process.arguments = ["-f"]
        process.launch()
    }

    func getVersion(javaHomePath: String) -> String {
        let process = Process()
        let env = ProcessInfo.processInfo.environment
        process.environment = env.merging(["JAVA_HOME": javaHomePath]) { _, new in new }
        let pipe = Pipe()

        if let path = Bundle.main.path(forResource: "cassandra", ofType: "", inDirectory: "App/bin") {
            process.launchPath = path
        }

        process.arguments = ["-v"]
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let version = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return version
        } else {
            return "Error !"
        }
    }

    func stopServer() {
        let process = Process()
        process.arguments = ["-c", "kill -9 $(lsof -t -i:9042)"]
        process.launchPath = "/bin/bash"
        process.launch()
    }

    @objc func openCqlsh(_: AnyObject) {
        if let path = Bundle.main.path(forResource: "cqlsh", ofType: "", inDirectory: "App/bin") {
            let task = Process()
            task.arguments = ["-b", "com.apple.terminal", path]
            task.launchPath = "/usr/bin/open"
            task.launch()
        }
    }

    @objc func openLogsDirectory(_: AnyObject) {
        if let path = Bundle.main.path(forResource: "debug.log", ofType: "", inDirectory: "App/logs") {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    func setupSystemMenuItem(javaHomePath: String) {
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        let icon = NSImage(named: "logo")!
        icon.isTemplate = true
        statusBarItem.image = icon

        let cassandraVersion = getVersion(javaHomePath: javaHomePath)

        versionMenuItem.title = "Apache Cassandra"
        versionMenuItem.title = "Apache Cassandra v\(cassandraVersion)"
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

    func applicationDidFinishLaunching(_: Notification) {
        if UserDefaults.standard.string(forKey: "JavaHomePath") == nil {
            askForJavaHomeAndStartServer()
        } else {
            let javaHomePath = UserDefaults.standard.string(forKey: "JavaHomePath")!
            setupSystemMenuItem(javaHomePath: javaHomePath)
            startServer(javaHomePath: javaHomePath)
        }
    }

    func applicationWillTerminate(_: Notification) {
        stopServer()
    }
}
