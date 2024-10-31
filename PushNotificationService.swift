//
//  PushNotificationService.swift
//  RealEstate
//
//  Created by xqsadness on 30/10/24.
//

//Migrate from Legacy FCM APIs to HTTP v1
import Foundation
//pod or package https://github.com/Kitura/Swift-JWT
import SwiftJWT

fileprivate struct ServiceAccountCredentials: Codable {
    let type: String
    let project_id: String
    let private_key_id: String
    let private_key: String
    let client_email: String
    let client_id: String
    let auth_uri: String
    let token_uri: String
    let auth_provider_x509_cert_url: String
    let client_x509_cert_url: String
}

fileprivate struct GoogleJWTClaims: Claims {
    let iss: String
    let scope: String
    let aud: String
    let iat: Date
    let exp: Date
}

struct PushNotificationService{
    
    static let shared = PushNotificationService()
    
    private init(){}
    
    func getAccessToken(completion: @escaping (String?) -> Void) {
        //PrivateKey is json file can download in Firebase console -> Project settings -> Service accounts -> generate new private key and then add it to your project.
        guard let serviceAccountPath = Bundle.main.path(forResource: "PrivateKey", ofType: "json"),
              let credentialsData = try? Data(contentsOf: URL(fileURLWithPath: serviceAccountPath)),
              let credentials = try? JSONDecoder().decode(ServiceAccountCredentials.self, from: credentialsData) else {
            completion(nil)
            return
        }
        
        let iat = Date()
        let exp = iat.addingTimeInterval(3600) // Token expired after 1 hour
        
        let claims = GoogleJWTClaims(
            iss: credentials.client_email,
            scope: "https://www.googleapis.com/auth/cloud-platform",
            aud: credentials.token_uri,
            iat: iat,
            exp: exp
        )
        
        var jwt = JWT(claims: claims)
        
        let privateKeyString = credentials.private_key
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        
        guard let privateKeyData = Data(base64Encoded: privateKeyString) else {
            completion(nil)
            return
        }
        
        let signer = JWTSigner.rs256(privateKey: privateKeyData)
        
        do {
            let jwtString = try jwt.sign(using: signer)
            
            // request to endpoint for get access token
            var request = URLRequest(url: URL(string: credentials.token_uri)!)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let bodyString = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwtString)"
            request.httpBody = bodyString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error fetching access token: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                
                // Parse response to extract the access token
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                   let dictionary = json as? [String: Any],
                   let accessToken = dictionary["access_token"] as? String {
                    completion(accessToken)
                } else {
                    completion(nil)
                }
            }
            task.resume()
        } catch {
            print("Error creating JWT: \(error)")
            completion(nil)
        }
    }
    
    func sendNotificationMessage(to token: String, title: String, body: String) {
        let projectID = "YOUR_PROJECT_ID" // Get in Firebase console -> Project settings
        let url = URL(string: "https://fcm.googleapis.com/v1/projects/\(projectID)/messages:send")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let message: [String: Any] = [
            "message": [
                "token": token,
                "notification": [
                    "title": title,
                    "body": body
                ],
                "data": [
                    "title": title,
                    "body": body,
                    "name" : "your_name"
                    // add some data if needed
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: message, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Notification sent successfully with image and sound!")
                } else {
                    print("Failed to send notification. Status code: \(httpResponse.statusCode)")
                    
                    if let data = data,
                       let responseBody = String(data: data, encoding: .utf8) {
                        print("Error response body: \(responseBody)")
                    }
                }
            }
        }
        task.resume()
    }
}

//MARK: - USAGE
//PushNotificationService.shared.getAccessToken {  accessToken in
//    guard let token = accessToken else {
//        print("Failed to retrieve access token.")
//        return
//    }
//    let toFcmToken = "FCM_TOKEN_DEVICE_HERE"
//    PushNotificationService.shared.sendNotificationMessage(to: toFcmToken, title: "Test title", body: "Test body",accessToken: token)
//}
