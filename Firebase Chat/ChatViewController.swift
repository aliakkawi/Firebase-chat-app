//
//  ChatViewController.swift
//  Firebase Chat
//
//  Created by Ali Akkawi on 10/18/16.
//  Copyright © 2016 Ali Akkawi. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController
import MobileCoreServices // for the video pick.
import AVKit// for being able to play a video.
import SDWebImage


class ChatViewController: JSQMessagesViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var messages = [JSQMessage]()// an empty array to hold the messages texts
    var firRef: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var profileImagesRef: FIRDatabaseReference!
    var profileImagesStorageRef: FIRStorageReference!
    var avatarImage: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // the app know where to put the bubles, to the left or to the right, if the current sender id is different from the sender id for a post it will put them to the left.
        
        
        
        firRef = FIRDatabase.database().reference().child("messages")
        
        // set the current user sender id and display name.
        if let currentUser = FIRAuth.auth()?.currentUser {
            
           profileImagesRef = FIRDatabase.database().reference().child("UsersInfo")
                self.senderId = currentUser.uid
            
                if (currentUser.isAnonymous){
                    
                    
                    self.senderDisplayName = "Anonymous"
                    
                }else {
                    
                    
                   // get all the google user info.
                    
                    for profile in currentUser.providerData {
                       let name = profile.displayName
                        
                        
                        if let theusername = name{
                            
                            self.senderDisplayName = theusername
                            
                        }
                        
                    }
                    
                    
                }
            
            
            observeMessages()
            
        }else {
            
            
            print("No current user ")
        }
            
        
        
        

    }
    
    
    
    func observeMessages(){
        
        
        
        
        firRef.observe(.childAdded, with: { snapshot in
            
            print(snapshot.value)
            
            // grap the childs and add them to the array.
            if let dict = snapshot.value as? [String: AnyObject]{
                
                let mediaType = dict["mediaType"] as! String
                let sName = dict["senderName"] as! String
                let sId = dict["senderId"] as! String
                
                
                switch (mediaType) {
                
                    
                    case "Text":
                    
                        let text = dict["text"] as! String
                        self.messages.append(JSQMessage(senderId: sId, displayName: sName, text: text))
                    
                    case "Image":
                    
                        let imageUrlString = dict["imageurl"] as! String
                        let url = NSURL(string: imageUrlString)
                        let imageData = NSData(contentsOf: url as! URL)
                        let picture = UIImage(data: imageData as! Data)
                        let photo = JSQPhotoMediaItem(image: picture)// We convert the string ti url -> data , make an image that hold data.
                        
                        
                
                        self.messages.append(JSQMessage(senderId: sId, displayName: sName, media: photo))
                        
                        // instead of the above we will use a 3rd part library to download the images and cache them.  Jared Library.
                        
                        //let downloader = SDWeb
                    
                    // adjust the tail of the image according to the current sender id.
                    
                        if self.senderId == sId { // if the image belong to the current users, set the image as an outgoing message.
                            
                            photo?.appliesMediaViewMaskAsOutgoing = true
                        } else {
                            
                            photo?.appliesMediaViewMaskAsOutgoing = false
                    }
                    
                    
                    
                    
                    case "Video":
                    
                        let videoUrlString = dict["videourl"] as! String
                        let videoUrl = NSURL(string: videoUrlString)
                        
                        
                        
                        let videoItem = JSQVideoMediaItem(fileURL: videoUrl as URL!, isReadyToPlay: true)
                        self.messages.append(JSQMessage(senderId: sId, displayName: sName, media: videoItem))
                    
                    
                        // adjust the tail of the video according to the current sender id.
                        
                        if self.senderId == sId { // if the image belong to the current users, set the image as an outgoing message.
                            
                            videoItem?.appliesMediaViewMaskAsOutgoing = true
                        } else {
                            
                            videoItem?.appliesMediaViewMaskAsOutgoing = false
                    }
                    
                default :
                    
                    print("No such a media type.")
                
                }
                
            self.collectionView.reloadData()
            }
            
            
        })
    }
    
    
    // when the user click the send button.
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        
        if let theText = text, let theSenderId = senderId, let theSenderDisplayName = senderDisplayName{
        
            
            
            //send the text to the firebase database.
            
            let messageRef = firRef.childByAutoId()
            let messageData = ["text": theText, "senderId": theSenderId, "senderName": theSenderDisplayName, "mediaType": "Text"]
            messageRef.setValue(messageData)
            self.view.endEditing(true)
            self.finishSendingMessage()// clear the text field after the message sent.
            
        }
    }
    
    // when the user click the atatch button.
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        
        // display a sheet alert to choose between picking an image or a video.
        
        let pickAlert = UIAlertController(title: "Media messages", message: "Please select a media", preferredStyle: .actionSheet)
        let pickAnImage = UIAlertAction(title: "Image", style: .default) { (imageaction) in
            
            // we want to display the image picker.
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            myPickerController.allowsEditing = true
            self.present(myPickerController, animated: true, completion: nil)
        }
        
        let pickVideo = UIAlertAction(title: "Video", style: .default) { (videoAction) in
            
            // we want to display the image picker.
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.mediaTypes = [kUTTypeMovie as String]// we have to import MobileCoreServices
            myPickerController.allowsEditing = true
            self.present(myPickerController, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        
        
        pickAlert.addAction(pickAnImage)
        pickAlert.addAction(pickVideo)
        pickAlert.addAction(cancelAction)
        
        present(pickAlert, animated: true, completion: nil)
        
    
        
    
    }
    
    
    // will be called when picking an image or a video..
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let theSenderId = self.senderId, let theSenderDisplayName = self.senderDisplayName {
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage { //  important, we added if let because it might be a video insetad of an image.   this will extract the info for the picked image.
        
                
                // upload the image to the Data Storage.
                if let imageData = UIImageJPEGRepresentation(pickedImage, 0.2){
                
                // uniqu id for the image
                let imgUid = NSUUID().uuidString
                
                // we have to inform firebase storage that we are dealing with jpeg
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                
                
                
                
                storageRef = FIRStorage.storage().reference().child("postImages").child(imgUid)
                storageRef.put(imageData, metadata: metadata, completion: { (metadata, error) in
                    
                    if error == nil {
                        
                        print("Upload success")
                        
                        // we need to add the data to database just like we did in the text.
                        
                        // get the image url.
                        
                        let imageUrl = metadata?.downloadURL()?.absoluteString
                        if let theUrl = imageUrl {
                            
                            let messageRef = self.firRef.childByAutoId()
                            let imageData = ["imageurl": theUrl, "senderId": theSenderId, "senderName": theSenderDisplayName, "mediaType": "Image"]
                            messageRef.setValue(imageData)
                        }
                        
                        
                    }else {
                        
                        
                        print("Error uploading image to Data storage.")
                    }
                })
                
                }
                
            }else if let pickedVideo = info[UIImagePickerControllerMediaURL] as? NSURL { // if the user picked a video.
                
                
                // upload the image to the Data Storage.
                let videoData = NSData(contentsOf: pickedVideo as URL)
                
                // uniqu id for the image
                let videoUid = NSUUID().uuidString
                
                // we have to inform firebase storage that we are dealing with mp4
                let metadata = FIRStorageMetadata()
                metadata.contentType = "video/mp4"
                
                
                storageRef = FIRStorage.storage().reference().child("postImages").child(videoUid)
                storageRef.put(videoData as! Data, metadata: metadata, completion: { (metadata, error) in
                    
                    
                    if error == nil {
                        
                        let videoUrl = metadata?.downloadURL()?.absoluteString
                        if let theVideoUrl = videoUrl {
                            
                            let messageRef = self.firRef.childByAutoId()
                            let videoData = ["videourl": theVideoUrl, "senderId": theSenderId, "senderName": theSenderDisplayName, "mediaType": "Video"]
                            messageRef.setValue(videoData)
                        }
                        
                        
                    } else {
                        
                        print("error uploading video.")
                    }
                })
                
                
            }
      }
        
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
    
    
    
    // in order to be able to play the video when touch we have to implement the following function.
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        
        
        // we need to check if it is a media message or a text message, and then if it is a media message we have to check if it is a video.
        
        let messageTapped = messages[indexPath.item]
        if messageTapped.isMediaMessage{
            
            // we have to build a video player.
            
            // first we have to grap the url for the video.
            
            if let videoUrl = messageTapped.media as? JSQVideoMediaItem {
                
               let player = AVPlayer(url: videoUrl.fileURL)
               let playerViewController = AVPlayerViewController()
               playerViewController.player = player
               present(playerViewController, animated: true, completion: nil)
            }
            
            
        }
        
    }
    
    //when we touch the white area the keyboard disappears.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
   
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let bubleFactory = JSQMessagesBubbleImageFactory()
        
        let message = messages[indexPath.row]
        
        if message.senderId == self.senderId { // this is an outgoing message
            
            return bubleFactory?.outgoingMessagesBubbleImage(with: UIColor.black)
            
        }else {
            
            
            return bubleFactory?.incomingMessagesBubbleImage(with: UIColor.red)
        }
        
        
    }
    
    
    func observeUserAvatar (index: IndexPath, senderId: String)  {
        
        
        
        var avImage: UIImage!
        // we have to get the profile image
        
        profileImagesRef.child(senderId).observe(.value, with: { (snapshot) in
            
            
            let snapshotvalue = snapshot.value as! [String: AnyObject]
            
            let profileImageString = snapshotvalue["profileimage"] as! String
            print("Profile image url \(profileImageString)")
            
            
            let profileImageUrl = NSURL(string: profileImageString)
            let profileImageData = NSData(contentsOf: profileImageUrl as! URL)
            avImage =  UIImage(data: profileImageData as! Data)
            self.avatarImage = avImage
        })
        
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        
        let indexMessage = messages[indexPath.item]
        if let messageSenderDisplayName = indexMessage.senderDisplayName, let messageSenderiD = indexMessage.senderId { // the sender id is the same as the user id.
            
            
            if messageSenderDisplayName == "Anonymous"{
                
                avatarImage = UIImage(named: "dummyUser")
                
            }else {
                
                observeUserAvatar (index: indexPath, senderId: messageSenderiD )
                
                
            }
            
        }
        
       return JSQMessagesAvatarImageFactory.avatarImage(with: avatarImage, diameter: 30)
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        return cell
    }
    
      
    @IBAction func signoutTapped(_ sender: AnyObject) {
        
        
        try! FIRAuth.auth()?.signOut()
        self.dismiss(animated: true, completion: nil)
    }
}
