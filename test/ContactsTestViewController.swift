//
//  ContactsTestViewController.swift
//  test
//
//  Created by 부리부리황 on 2022/02/23.
//

import UIKit
import Contacts
import CoreData

class ContactsTestViewController: UIViewController {
    
    @IBOutlet weak var sortsButton: UIButton!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var sortsPickerView: UIPickerView!
    @IBOutlet weak var sortsConfirmButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    
    
    var sortTypes = ["Firstname 내림차순", "Firstname 오름차순", "Lastname 내림차순", "Lastname 오름차순", "Phone 내림차순", "Phone 오름차순"]
    var selectedSortType = 0
    var contacts: [CNContact] = []
    
    enum Permission {
        case granted
        case denied
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.contactsTableView.dataSource = self
        self.contactsTableView.delegate = self
        
        self.sortsPickerView.dataSource = self
        self.sortsPickerView.delegate = self
        
        self.sortsButton.setTitle(self.sortTypes[0], for: .normal)
        
        self.readContacts()
    }
    
    //MARK: Device 연락처 관련
    func readContacts() {
        let store = CNContactStore()
        let keys = [CNContactIdentifierKey, CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else { return }
            
            DispatchQueue.global().async {
                do {
                    self.contacts = []
                    var count = 0
                    try store.enumerateContacts(with: request) { (contact, stop) in
                        self.contacts.append(contact)
                        count += 1
                        print("\(count) \(contact.givenName) \(contact.familyName) : \(contact.phoneNumbers.first?.value.stringValue), \(contact.emailAddresses.first?.value)")
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func writeContacts(completion: @escaping () -> Void = {}) {
        let store = CNContactStore()
        let request = CNSaveRequest()
        
        // 1000명의 임의의 연락처 추가
        for _ in 0..<1000 {
            let contact = CNMutableContact()
            contact.givenName = self.getRandomName(length: 10)
            contact.familyName = self.getRandomName(length: 5)
            let phone = CNLabeledValue(label: CNLabelHome , value: CNPhoneNumber(stringValue: self.getRandomPhoneNumberString()))
            contact.phoneNumbers = [phone]
        
            // getEmailString()에서 중복 없는 이메일을 가져옮
            let email = CNLabeledValue(label: CNLabelHome, value: self.getEmailString() as NSString)
            contact.emailAddresses = [email]
            
            request.add(contact, toContainerWithIdentifier: nil)
            
            // getEmailString 중복체크를 위해 임시 저장
            self.contacts.append(contact)
        }
        
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else { return }
            
            do {
                try store.execute(request)
                completion()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func resetContacts(completion: @escaping () -> Void = {}) {
        let store = CNContactStore()
        let request = CNSaveRequest()
        
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else { return }
            
            for contact in self.contacts {
                let mutableContact = contact.mutableCopy() as! CNMutableContact
                request.delete(mutableContact)
            }
            
            do {
                try store.execute(request)
                print("successfully reset contacts")
                completion()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    //MARK: CoreData 관련
    func resetCoreData(completion: @escaping () -> Void = {}) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
          
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ContactEntity")
        fetchRequest.returnsObjectsAsFaults = false
        
      do {
          let results =  try managedContext.fetch(fetchRequest)
          for obj in results {
              managedContext.delete(obj)
          }
          completion()
      } catch let error as NSError {
          print("Could not delete. \(error), \(error.userInfo)")
      }
    }
    
    func saveCoreData(contacts: [CNContact], completion: @escaping () -> Void = {}) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
          
        for contact in contacts {
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "ContactEntity", in: managedContext)!
            let contactManagedObject = NSManagedObject(entity: entity, insertInto: managedContext)
            contactManagedObject.setValue(contact.identifier, forKeyPath: "id")
            contactManagedObject.setValue(contact.givenName, forKeyPath: "firstname")
            contactManagedObject.setValue(contact.familyName, forKeyPath: "lastname")
            contactManagedObject.setValue(contact.phoneNumbers.first?.value.stringValue, forKeyPath: "phone")
            contactManagedObject.setValue(contact.emailAddresses.first?.value, forKeyPath: "email")
          
          do {
              try managedContext.save()
          } catch let error as NSError {
              print("Could not save. \(error), \(error.userInfo)")
          }
        }
        
        completion()
    }
    
    func loadCoreData(searchText: String? = nil, completion: @escaping () -> Void = {}) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
          
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ContactEntity")
        
        // 정렬 방법
        switch self.selectedSortType {
        case 0:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "firstname", ascending: false)]
        case 1:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "firstname", ascending: true)]
        case 2:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastname", ascending: false)]
        case 3:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastname", ascending: true)]
        case 4:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "phone", ascending: false)]
        case 5:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "phone", ascending: true)]
        default:
            break
        }
        
        if let text = searchText, !text.isEmpty {
            print("searchText: \(text)")
            fetchRequest.predicate = NSPredicate(format: "lastname CONTAINS[cd] %@ OR firstname CONTAINS[cd] %@ OR phone CONTAINS[cd] %@", text, text, text)
        }
        
        self.contacts = []
        do {
            let temps = try managedContext.fetch(fetchRequest)
            for temp in temps {
                let contact = CNMutableContact()
                contact.givenName = temp.value(forKeyPath: "firstname") as! String
                contact.familyName = temp.value(forKeyPath: "lastname") as! String
                let phone = CNLabeledValue(label: CNLabelHome , value: CNPhoneNumber(stringValue: temp.value(forKeyPath: "phone") as! String))
                contact.phoneNumbers = [phone]
                // getEmailString()에서 중복 없는 이메일을 가져옮
                let email = CNLabeledValue(label: CNLabelHome, value:  temp.value(forKeyPath: "email") as! NSString)
                contact.emailAddresses = [email]
                
                self.contacts.append(contact)
            }
            completion()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
          }
    }
    
    //MARK: Events 관련
    @IBAction func tabbedInit1000ContactsButton(_ sender: Any) {
        self.searchTextField.text = nil
        
        self.resetContacts() {
            self.writeContacts() {
                self.showAlert(message: "신규 연락처 1000개가 생성되었습니다.")
                self.readContacts()
            }
        }
    }
    
    @IBAction func tabbedCoreDataButton(_ sender: Any) {
        self.searchTextField.text = nil
    
        self.resetCoreData() {
            self.saveCoreData(contacts: self.contacts) {
                self.showAlert(message: "연락처 1000개가 CoreData에 저장 되었습니다.")
                self.loadCoreData() {
                    self.contactsTableView.reloadData()
                }
            }
        }
    }
    
    @IBAction func tabbedSearchButton(_ sender: Any) {
        self.view.endEditing(true)
        
        if self.searchTextField.text!.isEmpty { return }
        self.loadCoreData(searchText: self.searchTextField.text) {
            self.contactsTableView.reloadData()
        }
    }
    
    @IBAction func tabbedSortsButton(_ sender: Any) {
        self.contactsTableView.isHidden = true
        self.sortsPickerView.isHidden = false
        self.sortsConfirmButton.isHidden = false
    }
    
    @IBAction func tabbedSortsConfirmButton(_ sender: Any) {
        self.contactsTableView.isHidden = false
        self.sortsPickerView.isHidden = true
        self.sortsConfirmButton.isHidden = true
        
        self.loadCoreData(searchText: self.searchTextField.text) {
            self.contactsTableView.reloadData()
        }
    }
    
    //MARK: Utils
    func getRandomName(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func getRandomPhoneNumberString() -> String {
        let regionCodes = ["1", "7", "33", "34", "44", "49", "61", "63", "64", "65", "66", "81", "82", "84", "86", "852", "886", "91", "971"]
        let letters = "0123456789"
        return "\(regionCodes.randomElement()!) \(String((0..<4).map{ _ in letters.randomElement()!}))  \(String((0..<4).map{ _ in letters.randomElement()!}))"
    }
    
    func getEmailString() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let coms = [".com", ".net", ".co.kr", ".jp", ".aa"]
        let email =  String((0..<5).map{ _ in letters.randomElement()! }) + "@" + String((0..<5).map{ _ in letters.randomElement()! }) + coms.randomElement()!
        
        // 중복 체크
        for contact in self.contacts {
            let contactEmail = (contact.emailAddresses.first?.value ?? "") as String
            if email == contactEmail {
                print("중복 이메일 발견!! \(email)")
                return getEmailString()
            }
        }
        
        return email
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "확인", style: .cancel, handler: nil)
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ContactsTestViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("table count: \(self.contacts.count)")
        return self.contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsTableViewCell.id) as! ContactsTableViewCell
        cell.givenNameLabel.text = self.contacts[indexPath.row].givenName
        cell.familyNameLabel.text = self.contacts[indexPath.row].familyName
        cell.phoneLabel.text = self.contacts[indexPath.row].phoneNumbers.first?.value.stringValue
        //cell.emailLabel.text = self.contacts[indexPath.row].emailAddresses.first?.value
        
        return cell
    }
}

extension ContactsTestViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
         return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.sortTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
           return sortTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedSortType = row
        self.sortsButton.setTitle(self.sortTypes[row], for: .normal)
    }
}

class ContactsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var givenNameLabel: UILabel!
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    //@IBOutlet weak var emailLabel: UILabel!
    
    static let id = "ContactsTableViewCell"
}
