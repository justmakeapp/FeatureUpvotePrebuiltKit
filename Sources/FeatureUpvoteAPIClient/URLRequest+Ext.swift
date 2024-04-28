//
//  URLRequest+Ext.swift
//
//
//  Created by Long Vu on 28/4/24.
//

import Foundation

package extension URLRequest {
    func xApiKey(_ value: String) -> URLRequest {
        var mSelf = self
        mSelf.setValue(value, forHTTPHeaderField: "X-API-Key")
        return mSelf
    }
}
