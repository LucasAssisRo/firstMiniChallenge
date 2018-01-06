//
//  ListTableViewController.swift
//  App
//
//  Created by Lucas Assis Rodrigues on 13/12/2017.
//  Copyright © 2017 Apple Dev Academy. All rights reserved.
//

import UIKit
import ConnectivityServices
import MultipeerConnectivity
import SCLAlertView

class ListTableViewController: ConnectivityViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var selectedAvatar: AvatarPlanetButton!
    var selectedAvatarPosition: CGPoint?
    
    let invisibleTransform = CGAffineTransform(scaleX: 0.00000000000001, y: 0.00000000000001)
    
    override var isPromptVisible: Bool {
        didSet {
            print(self.inviteView.dialogBoxView)
            if let items = self.tabBarController?.tabBar.items {
                for button in items {
                    button.isEnabled = !self.isPromptVisible
                }
            }
            
            self.tableView.isScrollEnabled = !self.isPromptVisible
            if let avatarPosition = self.selectedAvatarPosition {
                UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    if (!self.isPromptVisible) {
                        self.inviteView.dialogBoxView.transform = self.invisibleTransform
                        self.inviteView.dialogBoxView.center = avatarPosition
                    } else {
                        self.inviteView.dialogBoxView.transform = CGAffineTransform.identity
                        self.inviteView.dialogBoxView.center = CGPoint(x: self.view.center.x,
                                                                       y: self.view.center.y - (self.tabBarController?.tabBar.frame.height ?? 0))
                    }
                }, completion: { finished in
                    if (finished && !self.isPromptVisible) {
                        self.inviteView.alpha = 0
                    }
                })
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setTableViewBackground(for: self)
        self.setUpPromptViews()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.updateFoundPeers()
        
        self.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func invitePeer(withId id: MCPeerID, profile: ProfileRequirements) {
        super.invitePeer(withId: id, profile: profile)
        if profile is UserProfile {
            OperationQueue.main.addOperation {
                self.isPromptVisible = true
            }
        }
    }
    
    override func dismissInvitationPrompt() {
        super.dismissInvitationPrompt()
        self.isPromptVisible = false
    }
    
    override func reloadData() {
        super.reloadData()
        UIView.transition(with: self.tableView,
                          duration: 0.35,
                          options: UIViewAnimationOptions.transitionCrossDissolve,
                          animations: { self.tableView.reloadData() },
                          completion:  nil)
    }
    
    override func setUpPromptViews() {
        super.setUpPromptViews()
        
        self.selectedAvatar = AvatarPlanetButton()
        self.selectedAvatar.frame.size = self.inviteView.avatarFrameView.frame.size - 5
        self.selectedAvatar.center = CGPoint(x: self.inviteView.avatarFrameView.bounds.midX, y: self.inviteView.avatarFrameView.bounds.midY)
        self.selectedAvatar.isUserInteractionEnabled = false
        self.selectedAvatar.alpha = 1
        self.inviteView.avatarFrameView.addSubview(self.selectedAvatar)
        print(self.inviteView.dialogBoxView)
        
        self.inviteView.dialogBoxView.transform = self.invisibleTransform
    }
}

extension ListTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? ListTableViewCell {
            if let profile = cell.userProfile {
                self.selectedAvatarPosition = CGPoint(x: cell.faceImageView.frame.midX,
                                                      y: cell.faceImageView.frame.midY + cell.frame.height * CGFloat(indexPath.item))
                self.selectedAvatar.cloneAttributesFrom(listTableViewCell: cell)
                
                self.inviteView.alpha = 1
                
                self.inviteView.dialogBoxView.center = self.selectedAvatarPosition!
                self.inviteView.usernameLabel.text = profile.username
                self.inviteView.gameButton.bgColor = profile.avatarSkin
                self.inviteView.chatButton.bgColor = profile.avatarSkin

                cell.faceImageView.backgroundColor = cell.faceImageView.backgroundColor
                var id: MCPeerID? = nil
                for peer in ServiceManager.instance.chatService.peers {
                    if (peer.displayName.components(separatedBy: "|")[0] == profile.id) {
                        id = peer
                        break
                    }
                }
                
                if (id != nil) {
                    self.invitePeer(withId: id!, profile: profile)
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}

extension ListTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 0
        } else {
            return self.people.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath) as! ListTableViewCell
        cell.userProfile = self.people[indexPath.row]
        return cell
    }
}
