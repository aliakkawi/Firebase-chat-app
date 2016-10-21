//
//  LoginViewController.swift
//  Firebase Chat
//
//  Created by Ali Akkawi on 10/18/16.
//  Copyright © 2016 Ali Akkawi. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    @IBOutlet weak var logInAnonymousButton: UIButton!
    var profileImagesStorageRef: FIRStorageReference!
    var profileImagesRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // change the background image.
        
        let bgImage = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        bgImage.layer.zPosition = -1
        bgImage.image = UIImage(named: "backgroundPhoto")
        view.addSubview(bgImage)
        
        
        
        // add a border to the button.
        
        logInAnonymousButton.layer.borderWidth = 2
        logInAnonymousButton.layer.borderColor = UIColor.white.cgColor
        
        
        // FOR THE GOOGLE SIGN IN
        
        GIDSignIn.sharedInstance().clientID = "1069356065021-nu64t3kdp48gvefml3qbesv4e07f3jhu.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            
            
            if user != nil {
                
                self.performSegue(withIdentifier: "gotochat", sender: nil)
                
            }
        })
    }
    
    // from the GIDSignInDelegate Protocol.
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        
        // here we take care of the google sign in .
        
        
        let credentials = FIRGoogleAuthProvider.credential(withIDToken: user.authentication.idToken, accessToken: user.authentication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
            
            
            if error == nil {
                
                if let email = user?.email{
                    
                    print("Email: \(email)")
                    
                    
                    // add profile image to the database and storage
                    
                    if let currentUser = user{
                        
                        self.profileImagesRef = FIRDatabase.database().reference().child("UsersInfo").child(currentUser.uid)
                        
                        
                    for profile in currentUser.providerData {
                        let name = profile.displayName
                        let photoURL = profile.photoURL
                        
                        if let theusername = name , let theprofilephotourl = photoURL{
                            
                            print("current user name: \(theusername)")
                            print("current user photo: \(theprofilephotourl)")
                            
                            // add the profile image to the storage
                            
                            let profileImageData = NSData(contentsOf: theprofilephotourl) // CONVERT THE URL INTO DATA.
                            
                            // add the profile image if not already exist.
                            
                            
                            self.profileImagesRef.observe(.value, with: { (snapshot) in
                                
                                if snapshot.hasChild("username"){
                                    
                                    
                                    print("child already exists and his value is")
                                    
                                }else {
                                    
                                    
                                    print("Child does not exists")
                                    self.addGoogleUserProfileImageToStorage(name: theusername, currentUserId: currentUser.uid, profileImageData: profileImageData!)                                }
                            })
                            
                            
                            
                            
                        }
                        
                        
                    }
                    }

                    
                    
                }
                
            }else {
                
                
                print(error?.localizedDescription)
                return
            }
        })
    }
    
    // a function to upload the image to firebase storage.
    // important the profile image will be save under his name and uid
    
    func addGoogleUserProfileImageToStorage(name: String, currentUserId: String, profileImageData: NSData){
        
        // uniqu id for the image
        
        // we have to inform firebase storage that we are dealing with jpeg
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        
        // upload the image
        
        profileImagesStorageRef = FIRStorage.storage().reference().child("profileimages")
        
        
        profileImagesStorageRef.child(currentUserId).put(profileImageData as Data, metadata: metadata) { (metadata, error) in
            
            
            print("profile image added")
            
            //add the image url to the database
            
            let downloadUrl = metadata?.downloadURL()?.absoluteString
            
            if let url = downloadUrl {
                
                let profileImageDict: [String: AnyObject] = ["profileimage": url as AnyObject, "username": name as AnyObject]
                
                self.profileImagesRef.setValue(profileImageDict)
            }
            
        }
    }

   
    @IBAction func loginAnonymouslyTapped(_ sender: AnyObject) {
        
        
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            
            
            if error == nil {
                
                self.performSegue(withIdentifier: "gotochat", sender: nil)
            }else {
                
                
                print(error?.localizedDescription)
                return
            }
            
            
        })
       
        
    }
    @IBAction func googleSignInTapped(_ sender: AnyObject) {
        
        
        GIDSignIn.sharedInstance().signIn()
               
    }
}
