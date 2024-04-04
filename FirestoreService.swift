//
//  FirestoreService.swift
//  Firebase
//
//  Created by xqsadness on 11/01/23.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

protocol FirestoreObject {
    func toDictionary() -> [String: Any]
    var id: String { get }
}

/**
 Adds an object of a specific type conforming to `FirestoreObject` to the Firestore database.
 - Parameters:
 - object: The object to be added to Firestore.
 - collectionName: The collection name where the object will be stored in Firestore.
 **/
func writeObjectToFirestore<T : FirestoreObject>(object: T, collectionName: NameObject, completion: @escaping (Error?) -> Void) {
    let db = Firestore.firestore()
    
    db.collection(collectionName.rawValue).document(object.id).setData(object.toDictionary()) { error in
        completion(error)
    }
}

/**
 Deletes an object of a specific type conforming to `FirestoreObject` from the Firestore database.
 - Parameters:
 - object: The object to be deleted from Firestore.
 - collectionName: The collection name from which the object will be deleted in Firestore.
 - completion: A closure that is called after the deletion operation is completed, providing an optional error if an error occurred during the operation.
 */
func deleteObjectFromFirestore<T: FirestoreObject>(object: T, collectionName: NameObject, completion: @escaping (Error?) -> Void) {
    let db = Firestore.firestore()
    
    db.collection(collectionName.rawValue).document(object.id).delete { error in
        completion(error)
    }
}

/**
 Deletes multiple objects of a specific type conforming to `FirestoreObject` from the Firestore database in a single batch operation.

 - Parameters:
   - objects: An array of objects to be deleted from Firestore.
   - collectionName: The collection name from which the objects will be deleted in Firestore.
   - completion: A closure that is called after the deletion operation is completed, providing an optional error if an error occurred during the operation.
 */
func deleteMultipleObjectsFromFirestore<T: FirestoreObject>(objects: [T], collectionName: NameObject, completion: @escaping (Error?) -> Void) {
    let db = Firestore.firestore()
    let batch = db.batch()
    
    for object in objects {
        let documentRef = db.collection(collectionName.rawValue).document(object.id)
        batch.deleteDocument(documentRef)
    }
    
    // Commit the batch operation to delete multiple objects
    batch.commit { error in
        completion(error)
    }
}

/**
 Deletes an image from Firebase Storage.

 - Parameters:
   - imageURL: The name or URL of the image file to be deleted.
   - completion: A closure that will be called when the image deletion is complete, with an optional `Error` parameter indicating any errors that occurred during the deletion. If the deletion is successful, the `Error` parameter will be `nil`.
*/
func deleteImageFromStorage(imageURL: String, completion: @escaping (Error?) -> Void) {
    // Create a reference to the Firebase Storage
    let storage = Storage.storage()
    
    // Get a reference to the image file based on the imageURL
    let imageRef = storage.reference(forURL: imageURL)
    
    // Delete the image file
    imageRef.delete { error in
        if let error = error {
            // An error occurred while deleting the image
            completion(error)
        } else {
            // Image deleted successfully
            completion(nil)
        }
    }
}

/**
 Fetches all objects from a Firestore collection of a specified`.
 - Parameters:
 - collectionName: The collection name from which the objects will be fetched in Firestore.
 - completion: A closure that is called after the fetch operation is completed, providing a `QuerySnapshot` containing the fetched documents and an optional error if an error occurred during the operation.
 */
func fetchAllObjects(collectionName: NameObject, completion: @escaping (QuerySnapshot?, Error?) -> Void) {
    let db = Firestore.firestore()
    
    db.collection(collectionName.rawValue).getDocuments() { (querySnapshot, error) in
        completion(querySnapshot, error)
    }
}

/**
 Fetches a single document from a Firestore collection based on its `id`.
 - Parameters:
 - collectionName: The collection name from which the objects will be fetched in Firestore.
 - id: The unique identifier (id) of the document to fetch.
 - completion: A closure that is called when the document is successfully fetched or if an error occurs.
 - documentSnapshot: A `DocumentSnapshot` containing the fetched document, if successful; otherwise, `nil`.
 - error: An `Error` object describing any errors that occurred during the operation, if any.
 */
func fetchSingleObject(collectionName: NameObject, id: String, completion: @escaping (DocumentSnapshot?, Error?) -> Void) {
    let db = Firestore.firestore()
    
    let documentReference = db.collection(collectionName.rawValue).document(id)
    
    documentReference.getDocument { (documentSnapshot, error) in
        completion(documentSnapshot, error)
    }
}

/**
 Fetches objects from a Firestore collection based on specified conditions.
 - Parameters:
 - collectionName: The collection name from which the objects will be fetched in Firestore.
 - conditions: An array of tuples, each containing the field name, operator, and value for a query condition.
 - completion: A closure that is called after the fetch operation is completed, providing a `QuerySnapshot` containing the fetched documents and an optional error if an error occurred during the operation.
 - Use conditions like this
 let conditions: [(fieldName: String, `operator`: Operator, value: Any)] = [
 ("name", .isEqualTo, "C")
 ]
 */
func fetchObjectsWithConditions(collectionName: NameObject, conditions: [(fieldName: String, `operator`: Operator, value: Any)], completion: @escaping (QuerySnapshot?, Error?) -> Void) {
    let db = Firestore.firestore()
    let collectionRef = db.collection(collectionName.rawValue)
    
    var query: Query = collectionRef
    
    for condition in conditions {
        let (fieldName, `operator`, value) = condition
        
        // If `operator` is `.none`, then the `query.whereField` operation is not performed
        if `operator` != .none{
            switch `operator` {
            case .isEqualTo:
                query = query.whereField(fieldName, isEqualTo: value)
            case .isLessThan:
                query = query.whereField(fieldName, isLessThan: value)
            case .isGreaterThan:
                query = query.whereField(fieldName, isGreaterThan: value)
            case .arrayContains:
                query = query.whereField(fieldName, arrayContains: value)
            case .isLessThanOrEqualTo:
                query = query.whereField(fieldName, isLessThanOrEqualTo: value)
            case .isGreaterThanOrEqualTo:
                query = query.whereField(fieldName, isGreaterThanOrEqualTo: value)
            case .isNotEqualTo:
                query = query.whereField(fieldName, isNotEqualTo: value)
            case .none:
                break
            }
        }
    }
    
    query.getDocuments() { (querySnapshot, error) in
        completion(querySnapshot, error)
    }
}

/**
 Enum defining names of Firestore collections to be used for different types of objects. Each case corresponds to a specific Firestore collection name.
 */
enum NameObject: String{
    case product = "products"
    case coupon = "coupons"
    case order = "orders"
    case payment = "payments"
    case cart = "carts"
    case address = "address"
    case category = "categorys"
    case discount = "discounts"
    case productOption = "productOptions"
    case user = "users"
    case notification = "notification"
}

// Add more conditions as needed
enum Operator: String{
    case none = ""
    case isEqualTo = "isEqualTo"
    case isLessThan = "isLessThan"
    case isGreaterThan = "isGreaterThan"
    case arrayContains = "arrayContains"
    case isLessThanOrEqualTo = "isLessThanOrEqualTo"
    case isGreaterThanOrEqualTo = "isGreaterThanOrEqualTo"
    case isNotEqualTo = "isNotEqualTo"
}


/*
 Usage example for fetching objects from a Firestore collection and handling the fetched data.

 Example usage includes fetching a list of `CategoryModel` objects from the Firestore `categorys` collection.

 - Note: In this example, I define a `CategoryModel` conforming to the `FirestoreObject` protocol and implement the required functions `toDictionary` and `id`.

 - Note: The function `fetchAllCategory` is used to fetch all documents from the Firestore `categorys` collection, convert them into `CategoryModel` objects, and update the `dataCategorys` property, which can be used to display the data in the user interface.

 Example usage:

 -- Model
 struct CategoryModel: FirestoreObject{
    var categoryId: String = ""
    var name: String = ""
    var thumbnailCategory: String = ""
    
    var id:String{
        return categoryId
    }
    
    func toDictionary() -> [String: Any] {
        let data: [String: Any] = [
            "categoryId" : self.categoryId,
            "name": self.name,
            "thumbnailCategory": self.thumbnailCategory,
        ]
        
        return data
    }
}

 -- VM
 struct CategoryModel: FirestoreObject{
     var categoryId: String = ""
     var name: String = ""
     var thumbnailCategory: String = ""
     
     var id:String{
         //return -> categoryId
         return categoryId
     }
     
     func toDictionary() -> [String: Any] {
         let data: [String: Any] = [
             "categoryId" : self.categoryId,
             "name": self.name,
             "thumbnailCategory": self.thumbnailCategory,
         ]
         
         return data
     }
 }

-- fetch
 func fetchAllCategory() {
     fetchAllObjects(collectionName: .category) { querySnapshot, error in
         if let error = error {
             print("Error getting documents: \(error)")
         } else {
             var data: [CategoryModel] = []
             
             for document in querySnapshot!.documents {
                 let categoryData = document.data()
                 
                 if let category = parseCategory(from: categoryData) {
                     data.append(category)
                 }
             }
             withAnimation {
                 self.dataCategorys = data
             }
         }
     }
 }

 func parseCategory(from categoryData: [String: Any]) -> CategoryModel? {
        guard let name = categoryData["name"] as? String ,
              let categoryId = categoryData["categoryId"] as? String,
              let thumbnailCategory = categoryData["thumbnailCategory"] as? String else {
                  return nil
              }
        
        return CategoryModel(categoryId: categoryId, name: name, thumbnailCategory: thumbnailCategory)
    }

-- Write
 func addCategory() {
        let categoryId = UUID().uuidString
        
        let storageRef = Storage.storage().reference().child("Category_Images").child(categoryId)
        
        guard let thumbnailCategory = thumbnailCategory else {
            LocalNotification.shared.message("Default profile image not found", .warning)
            return
        }
        
        // convert type image to png
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        
        // Convert the image into JPEG and compress the quality to reduce its size
        let data = thumbnailCategory.jpegData(compressionQuality: 0.2)
        
        // Upload the image
        if let data = data {
            storageRef.putData(data, metadata: metaData) { (metadata, error) in
                if let error = error {
                    LocalNotification.shared.message("Error while uploading file: \(error.localizedDescription)", .error)
                }else{
                    Task{
                        let urlCategory = try await storageRef.downloadURL()
                        
                        self.updateCategoryWithImage(categoryId: categoryId, urlImage: urlCategory.absoluteString)
                        //add category with downloadURL from storage and fetch category
                       
                    }
                }
            }
        }
    }
*/
