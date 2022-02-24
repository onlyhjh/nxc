//
//  FoldersTestViewController.swift
//  test
//
//  Created by 부리부리황 on 2022/02/23.
//

import UIKit

class FoldersTestViewController: UIViewController {

    @IBOutlet weak var foldersTableView: UITableView!
    
    static let id = "FoldersTestViewController"
    var commonFolderPath: URL!
    var folders: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.foldersTableView.dataSource = self
        self.foldersTableView.delegate = self
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        commonFolderPath = docURL.appendingPathComponent("CommonFolder")
    }
    
    func reloadFolders() {
        self.folders = []
        
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: self.commonFolderPath,
                    includingPropertiesForKeys: nil
                )
            for url in directoryContents {
                self.folders.append("\(url.lastPathComponent)")
                //print("???: \(url.lastPathComponent)")
            }
        } catch {
            print(error.localizedDescription)
            return
        }
        
        self.folders = self.folders.sorted {$0.localizedStandardCompare($1) == .orderedAscending}
        self.foldersTableView.reloadData()
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "확인", style: .cancel, handler: nil)
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func tabbedInit1000FoldersButton(_ sender: Any) {
        // 기본 폴더를 삭제하고 다시 시작
        if FileManager.default.fileExists(atPath: self.commonFolderPath.path) {
            do {
                try FileManager.default.removeItem(atPath: self.commonFolderPath.path)
            } catch {
                print(error.localizedDescription)
                return
            }
        }
        // 기본 폴더 생성
        do {
            try FileManager.default.createDirectory(atPath: self.commonFolderPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
            return
        }
        // 기본 폴더에 1000개의 폴더 생성
        for i in 0..<1000 {
            let newFolderPath = commonFolderPath.appendingPathComponent("untitled \(i)")
            do {
                try FileManager.default.createDirectory(atPath: newFolderPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        self.showAlert(message: "1000개의 신규 폴더가 생성되었습니다.\nuntitled 0~999" )
        self.reloadFolders()
    }
    
    @IBAction func tabbedDelete3FoldersButton(_ sender: Any) {
        let deleteFolderArray = ["untitled 521", "untitled 717", "untitled 78"]
        
        for deleteFolder in deleteFolderArray {
            let deleteFolderPath = commonFolderPath.appendingPathComponent(deleteFolder)
            
            if FileManager.default.fileExists(atPath: deleteFolderPath.path) {
                do {
                    try FileManager.default.removeItem(atPath: deleteFolderPath.path)
                } catch {
                    print(error.localizedDescription)
                    return
                }
            }
        }
        
        self.showAlert(message: "3개의 폴더가 삭제되었습니다.\n\(deleteFolderArray[0]), \(deleteFolderArray[1]), \(deleteFolderArray[2]))" )
        self.reloadFolders()
    }
    
    @IBAction func tabbedAddNewFolderButton(_ sender: Any) {
        // 기존 데이터 다시 로딩
        self.reloadFolders()
        // 번호 대로 존재하는 이름이 있는지 확인
        for i in 0...Int.max {
            let newFolderPath = commonFolderPath.appendingPathComponent("untitled \(i)")
            // 존재하지 않는 다면 추가함
            if !FileManager.default.fileExists(atPath: newFolderPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: newFolderPath.path, withIntermediateDirectories: true, attributes: nil)
                    //print("??? 추가된 폴더: \(newFolderPath.lastPathComponent)")
                    self.showAlert(message: "1개의 폴더가 추가되었습니다.\n\(newFolderPath.lastPathComponent)" )
                    self.reloadFolders()
                    return
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

extension FoldersTestViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FoldersTableViewCell.id) as! FoldersTableViewCell
        cell.titleLabel.text = self.folders[indexPath.row]
        return cell
    }
}

class FoldersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    static let id = "FoldersTableViewCell"
}
