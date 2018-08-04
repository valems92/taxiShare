import UIKit
import DshareFramework
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController, MessageReceivedDelegate {
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    let EXIT_MESSAGE:String = " has left the chat"
    let NOTIFICATION_TITLE:String = "New Message from "
    
    var users:[String]?
    var usersFcmTokens:[String]?
    
    var messages = [JSQMessage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        self.senderDisplayName = ""
        Model.instance.getCurrentUser(){ (user) in
            let fName = user!["fName"] as! String
            let lName = user!["lName"] as! String
            
            self.senderDisplayName = fName + " " + lName
        }
        
        Model.instance.delegateChatModel(clss: self)
        Model.instance.observeMessages()
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 5, height: 5)
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 5, height: 5)
        
        inputToolbar.contentView.leftBarButtonItem = nil
    }
    
    //Set the message text color
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    //Setting up the Data Source and Delegate
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    //Override the following method to make the “Send” button save a message to the Firebase database.
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        Model.instance.sendMessage(senderID: senderId, senderName: senderDisplayName, recieversIds: users!, text: text, exitMessage: false)
        collectionView.reloadData()
        finishSendingMessage()
        sendNotification(senderId: senderId, senderName: senderDisplayName, messageText: text)
    }
    
    func sendNotification(senderId: String, senderName:String, messageText: String) {
        var senderFcmToken:String? = nil
        Model.instance.getUserById(id: senderId) { (user) in
            senderFcmToken = user!["fcmToken"] as? String
        }
        
        let tokens = usersFcmTokens?.filter {$0 != senderFcmToken}
        let title = NOTIFICATION_TITLE + senderName
        Notifications.instance.sendNotification(tokens: tokens!, messageTitle: title, messageText: messageText, url:"http://127.0.0.1:3000/newMessage", method: .POST) { (res, error) in
        }
    }
    
    func messageRecieved(senderID:String, senderName:String, recieversIds:[String], text:String, exitMessage:Bool) {
        if senderID == Model.instance.getCurrentUserId() {
            for recieverId in recieversIds {
                for user in users! {
                    if recieverId == user {
                        messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                        collectionView.reloadData()
                        break
                    }
                }
            }
        }
        else {
            for recieverId in recieversIds {
                if recieverId == Model.instance.getCurrentUserId() {
                    for userID in users! {
                        if senderID == userID { 
                            messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                            if exitMessage {
                                inputToolbar.contentView.rightBarButtonItem = nil
                                inputToolbar.contentView.textView.isEditable = false
                            }
                            collectionView.reloadData()
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParentViewController {
            Model.instance.removeMessegesObserver()
        }
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title:"Match Founded", message:"Congratulations! you found a match. we look forward to helping you in future searches", preferredStyle:.alert)
        
        let okAction = UIAlertAction(title:"OK", style:.default) { (action:UIAlertAction!) in
            Model.instance.sendMessage(senderID: self.senderId, senderName: self.senderDisplayName, recieversIds: self.users!, text: self.senderDisplayName + self.EXIT_MESSAGE, exitMessage: true)
            
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyBoard.instantiateViewController(withIdentifier: "SearchPage") as! SearchViewController
            
            self.navigationController!.pushViewController(viewController, animated: true)
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated:true, completion:nil)
    }
}
