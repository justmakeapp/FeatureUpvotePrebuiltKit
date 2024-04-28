//
//  AbstractAPIClient.swift
//
//
//  Created by Long Vu on 8/3/24.
//

import Foundation
import SwiftyJSON

package protocol AbstractAPIClient {
    func processResponseData(data: Data, statusCode: Int) throws -> Data
}

package extension AbstractAPIClient {
    @discardableResult
    func processResponseData(data: Data, statusCode: Int) throws -> Data {
        let json = JSON(data)
        if let isSuccess = json["success"].bool, isSuccess {
            return data
        } else if let message = json["error"].string {
            throw NSError(
                domain: "",
                code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        } else {
            throw NSError(
                domain: "",
                code: statusCode,
                userInfo: nil
            )
        }
    }
}
