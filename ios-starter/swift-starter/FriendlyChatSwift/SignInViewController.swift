//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Firebase

@objc(SignInViewController)
class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let user = FIRAuth.auth()?.currentUser {
            self.signedIn(user)
        }
    }
    
    @IBAction func didTapSignIn(_ sender: AnyObject) {
        
        guard
            let email = self.emailField.text,
            let password = self.passwordField.text else {
                fatalError("There was an issue unwrapping the user email and password in the SignInVC.")
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if let error = error {
                fatalError("There was an error sigining in the user: \(error.localizedDescription)")
            } else if let user = user {
                self.signedIn(user)
            }
        })
    }
    
    @IBAction func didTapSignUp(_ sender: AnyObject) {
        
        guard
            let email = self.emailField.text,
            let password = self.passwordField.text else {
                fatalError("There was an issue unwrapping the user email and password in the SignInVC.")
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if let error = error {
                fatalError("There was an error sigining in the user: \(error.localizedDescription)")
            } else if let user = user {
                self.setDisplayName(user)
            }
        })
    }
    
    func setDisplayName(_ user: FIRUser?) {
        
        let changeRequest = user?.profileChangeRequest()
        changeRequest?.displayName = user?.email?.components(separatedBy: "@")[0]
        changeRequest?.commitChanges(completion: { (error) in
            if let error = error {
                fatalError("There was an error setting the display name in the SignInVC: \(error.localizedDescription)")
            }
            self.signedIn(FIRAuth.auth()?.currentUser)
        })
    }
    
    @IBAction func didRequestPasswordReset(_ sender: AnyObject) {
        
        let prompt = UIAlertController.init(title: "", message: "Email", preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
            
            let userInput = prompt.textFields![0].text
            if userInput!.isEmpty{
                return
            }
            FIRAuth.auth()?.sendPasswordReset(withEmail: userInput!, completion: { (error) in
                if let error = error {
                    fatalError("There was an error seding the password reseet email in the SignInVC: \(error.localizedDescription)")
                }
            })
        })
        
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(okAction)
        self.present(prompt, animated: true, completion: nil)
    }
    
    func signedIn(_ user: FIRUser?) {
        MeasurementHelper.sendLoginEvent()
        
        AppState.sharedInstance.displayName = user?.displayName ?? user?.email
        AppState.sharedInstance.photoURL = user?.photoURL
        AppState.sharedInstance.signedIn = true
        let notificationName = Notification.Name(rawValue: Constants.NotificationKeys.SignedIn)
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: nil)
        performSegue(withIdentifier: Constants.Segues.SignInToFp, sender: nil)
    }
    
    func signOut(_ sender: UIButton) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            self.dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError{
            print("There was an error signing out: \(signOutError.localizedDescription)")
        }
    }
    
}
