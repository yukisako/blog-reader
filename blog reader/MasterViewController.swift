//
//  MasterViewController.swift
//  blog reader
//
//  Created by 迫 佑樹 on 2016/01/03.
//  Copyright © 2016年 迫 佑樹. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate{
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDel: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        
        
        let url = NSURL(string: "https://www.googleapis.com/blogger/v3/blogs/4314185722199117461/posts?key=")!
        //key=の所に，google blogger API keyを入力．
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithURL(url) { (data, response, error) -> Void in
            
            if let urlContent = data {
                
                if error != nil {
                    print(error)
                } else {
                    //print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                    
                    do{
                        let jsonResult = try NSJSONSerialization.JSONObjectWithData(urlContent, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        
                        if jsonResult.count > 0{
                            
                            //何度も同じデータが格納されるので，一旦すべて削除する処理
                            var request = NSFetchRequest(entityName: "Posts")
                            request.returnsObjectsAsFaults = false
                            
                            do{
                                var results = try context.executeFetchRequest(request)
                                
                                if results.count > 0{
                                    
                                    for result in results{
                                        
                                        context.deleteObject(result as! NSManagedObject)
                                        
                                        do {
                                            try context.save()
                                        } catch {
                                            print("error")
                                        }
                                        
                                    }
                                    
                                }
                            
                            }
                            
                            
                            
                            
                            
                            if let items = jsonResult["items"] as? NSArray{
                                
                                for item in items{
                                    
                                    if let title = item["title"] as? String{
                                        
                                        if let content = item["content"] as? String{
                                            
                                            print(title)
                                            
                                            var newPost: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Posts", inManagedObjectContext: context) as! NSManagedObject
                                            
                                            newPost.setValue(title, forKey: "title")
                                            newPost.setValue(content, forKey: "content")
                                            
                                            do{
                                                try context.save()
                                            } catch{
                                                print("セーブ失敗")
                                            }
                                            
                                        }
                                        
                                        
                                    }
                                }
                                
                            }
                            
                            
                        }
                        //テスト用コード
                        /*
                        var request = NSFetchRequest(entityName: "Posts")
                        
                        request.returnsObjectsAsFaults = false
                        
                        do{
                            var result = try context.executeFetchRequest(request)
                            
                            print(result)
                        } catch {
                            
                        }
                        */
                        
                        self.tableView.reloadData()
                        
                    } catch {
                        print("JSON Serialization failed")
                    }
                    
                }

                
            }
            
            
            
            
        }
        
        task.resume()
    
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {

            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
        cell.textLabel!.text = object.valueForKey("title")!.description
    }
    
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // コアデータのエンティティを選り出して表示
        let entity = NSEntityDescription.entityForName("Posts", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // titleでソートする
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

}

