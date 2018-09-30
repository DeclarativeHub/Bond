//
//  AppDelegate.swift
//  Bond-App
//
//  Created by Srdan Rasic on 29/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import UIKit
import Bond
import ReactiveKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

class CustomBinder: TableViewBinderDataSource<TreeChangeset<Array2D<String, Int>>> {

    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return changeset?.dataSource[[section]].value.section
    }

//    override func applyChageset(_ changeset: TreeChangeset<Array2D<String, Int>>) {
//        tableView?.reloadData()
//    }
}

class ViewController: UIViewController {


    let tableView = UITableView()
    let mutableArray = MutableObservableArray2D<String, Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.estimatedRowHeight = 50
        randomOperation()

        mutableArray.bind(to: self) { s, d in
            print(d.diffs, d.collection)
        }

        mutableArray.bind(to: tableView, cellType: UITableViewCell.self, using: CustomBinder()) { (cell, data) in
            cell.textLabel?.text = "\(data)"
        }
    }


    func randomOperation() {
        mutableArray.apply(.randomOperation(collection: mutableArray.value.collection))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.randomOperation()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
}

extension TreeChangeset.Operation where Collection == Array2D<String, Int> {

    static func randomOperation(collection: Collection) -> TreeChangeset<Collection>.Operation {
        let data = [0, 0].randomElement() == 0 ? Array2DElement(item: Int.random(in: 11..<100)) : Array2DElement(section: "\(Int.random(in: 11..<100))")
        let element = TreeNode(data)
        let indices = collection.indices
        guard indices.count > 3 else {
            return .insert(TreeNode(Array2DElement(section: "Sec \(Int.random(in: 11..<100))"), [TreeNode(Array2DElement(item: 0))]), at: [0])
        }
        switch [0, 0, 1, 3, 4].randomElement() {
        case 0:
            var at = indices.randomElement()!
            if Bool.random() && at.count == 1 {
                at = at.appending(0)
            }
            if at.count == 2 {
                return .insert(TreeNode(Array2DElement(item: Int.random(in: 11..<100))), at: at)
            } else {
                return .insert(TreeNode(Array2DElement(section: "\(Int.random(in: 11..<100))")), at: at)
            }
        case 1:
            let at = indices.randomElement()!
            return .delete(at: at)
        case 2:
            let at = indices.randomElement()!
            return .update(at: at, newElement: element)
        case 3:
            guard let from = indices.filter({ $0.count == 2 }).randomElement() else { return randomOperation(collection: collection) }
            var collection = collection
            collection.remove(at: from)
            let to = collection.indices.filter { $0.count == 2}.randomElement() ?? from // to endindex
            return .move(from: from, to: to)
        case 4:
            guard let from = indices.filter({ $0.count == 1 }).randomElement() else { return randomOperation(collection: collection) }
            var collection = collection
            collection.remove(at: from)
            let to = collection.indices.filter { $0.count == 1 }.randomElement() ?? from // to endindex
            return .move(from: from, to: to)
        default:
            fatalError()
        }
    }
}
