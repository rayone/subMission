import AppKit

@MainActor
func run() {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}

Task { @MainActor in
    run()
}
