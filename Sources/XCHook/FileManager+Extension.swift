//
//  FileManager+Extension.swift
//  
//
//  Created by Takuto Nakamura on 2022/04/27.
//

import Foundation

extension FileManager {
    static var homeDirectory: String? {
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            return self.default.string(withFileSystemRepresentation: home,
                                       length: strlen(home))
        }
        return nil
    }
}
