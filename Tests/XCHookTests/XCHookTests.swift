import XCTest
@testable import XCHook

final class XCHookTests: XCTestCase {
    var sut: XCHookRegister!

    override func setUpWithError() throws {
        super.setUp()
        sut = try XCTUnwrap(XCHookRegister())
    }

    func testCreateRemoveXCHookDirectory() {
        sut.createXCHookDirectory()
        let createActual = Shell.run("test", "-e", sut.xchookPath).succeeded
        XCTAssertTrue(createActual)

        sut.removeXCHookDirectory()
        let removeActual = Shell.run("test", "-e", sut.xchookPath).succeeded
        XCTAssertFalse(removeActual)
    }

    func testCopyFiles() {
        sut.createXCHookDirectory()
        sut.copyFiles()
        let xchookActual = Shell.run("ls", "-1", sut.xchookPath).outputs
        XCTAssertTrue(xchookActual[0] == "Message.swift")
        XCTAssertTrue(xchookActual[1] == "run_scripts")
        let runScriptsActual = Shell.run("ls", "-1", "\(sut.xchookPath)/run_scripts").outputs
        XCTAssertTrue(runScriptsActual[0] == "build_fails.sh")
        XCTAssertTrue(runScriptsActual[1] == "build_start.sh")
        XCTAssertTrue(runScriptsActual[2] == "build_succeeds.sh")
        XCTAssertTrue(runScriptsActual[3] == "testing_fails.sh")
        XCTAssertTrue(runScriptsActual[4] == "testing_start.sh")
        XCTAssertTrue(runScriptsActual[5] == "testing_succeeds.sh")
        sut.removeXCHookDirectory()
    }

    func testOverwritePlists() throws {
        let loadURL = try XCTUnwrap(sut.modulePlist(name: "xcode_before_overwrite"))
        let writeURL = loadURL.deletingLastPathComponent()
            .appendingPathComponent("xcode_after_overwrite.plist")
        let actual = sut.overwritePlist(loadURL: loadURL, writeURL: writeURL)
        XCTAssertTrue(actual)
    }

    func testResetPlists() throws {
        let loadURL = try XCTUnwrap(sut.modulePlist(name: "xcode_before_reset"))
        let writeURL = loadURL.deletingLastPathComponent()
            .appendingPathComponent("xcode_after_reset.plist")
        let actual = sut.resetPlist(loadURL: loadURL, writeURL: writeURL)
        XCTAssertTrue(actual)
    }

    func xtestInstall() {
        sut.install()
    }

    func xtestUninstall() {
        sut.uninstall()
    }
}
