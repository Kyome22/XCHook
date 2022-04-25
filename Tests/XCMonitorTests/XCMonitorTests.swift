import XCTest
@testable import XCMonitor

final class XCMonitorTests: XCTestCase {
    var sut: XCMonitor!

    override func setUpWithError() throws {
        super.setUp()
        sut = try XCTUnwrap(XCMonitor())
    }

    func testCreateRemoveXCMonitorDirectory() {
        sut.createXCMonitorDirectory()
        let createActual = Shell.run("test", "-e", sut.xcmonitorPath).succeeded
        XCTAssertTrue(createActual)

        sut.removeXCMonitorDirectory()
        let removeActual = Shell.run("test", "-e", sut.xcmonitorPath).succeeded
        XCTAssertFalse(removeActual)
    }

    func testCopyFiles() {
        sut.createXCMonitorDirectory()
        sut.copyFiles()
        let xcmonitorActual = Shell.run("ls", "-1", sut.xcmonitorPath).outputs
        XCTAssertTrue(xcmonitorActual[0] == "Message.swift")
        XCTAssertTrue(xcmonitorActual[1] == "run_scripts")
        let runScriptsActual = Shell.run("ls", "-1", "\(sut.xcmonitorPath)/run_scripts").outputs
        XCTAssertTrue(runScriptsActual[0] == "build_fails.sh")
        XCTAssertTrue(runScriptsActual[1] == "build_start.sh")
        XCTAssertTrue(runScriptsActual[2] == "build_succeeds.sh")
        XCTAssertTrue(runScriptsActual[3] == "testing_fails.sh")
        XCTAssertTrue(runScriptsActual[4] == "testing_start.sh")
        XCTAssertTrue(runScriptsActual[5] == "testing_succeeds.sh")
        sut.removeXCMonitorDirectory()
    }

    func testOverwritePlists() throws {
        let loadURL = try XCTUnwrap(sut.modulePlist(name: "xcode_before_overwrite"))
        let writeURL = try XCTUnwrap(sut.modulePlist(name: "xcode_after_overwrite"))
        let actual = sut.overwritePlist(loadURL: loadURL, writeURL: writeURL)
        XCTAssertTrue(actual)
    }

    func testResetPlists() throws {
        let loadURL = try XCTUnwrap(sut.modulePlist(name: "xcode_before_reset"))
        let writeURL = try XCTUnwrap(sut.modulePlist(name: "xcode_after_reset"))
        let actual = sut.resetPlist(loadURL: loadURL, writeURL: writeURL)
        XCTAssertTrue(actual)
    }

    func testInstall() {
        sut.install()
    }
}
