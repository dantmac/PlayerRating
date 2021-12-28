//
//  ViewController.swift
//  PlayerRating
//
//  Created by admin on 11.05.2021.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    
    var player: Player!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.selectedSegmentTintColor = .white
            
            let whiteTitleTextAtributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAtributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAtributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAtributes, for: .selected)
        }
    }
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var playerPhoto: UIImageView!
    @IBOutlet weak var lastGameLabel: UILabel!
    @IBOutlet weak var numberOfGamesLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoice: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var rateButton: UIButton!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentedCtrl()
    }
    
    @IBAction func startPressed(_ sender: UIButton) {
        player.timesPlaying += 1
        player.lastGame = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedPlayer: player)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func ratePressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate Menu", message: "Rate this player", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alertController.addTextField { textField in
            textField.keyboardType = .decimalPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func update(rating: Double) {
        player.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedPlayer: player)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
    
    private func insertDataFrom(selectedPlayer player: Player) {
        guard let photoData = player.photoData,
              let lastGame = player.lastGame else { return }
        
        playerPhoto.image = UIImage(data: photoData)
        lastGameLabel.text = "Last game: \(dateFormatter.string(from: lastGame))"
        playerLabel.text = player.player
        teamNameLabel.text = player.team
        myChoice.isHidden = !(player.myChoice)
        ratingLabel.text = "Rating: \(player.rating) / 10"
        numberOfGamesLabel.text = "Number of games: \(player.timesPlaying)"
        segmentedControl.backgroundColor = player.tintColor as? UIColor
    }
    
    private func getDataFromFile() {
        let userDefaults = UserDefaults.standard
        let dataWasPreloaded = userDefaults.bool(forKey: ConfigurationKeys.flagKey)
        if dataWasPreloaded == false {
            
            guard let pathToFile = Bundle.main.path(forResource: ConfigurationKeys.dataKey, ofType: ConfigurationKeys.plistKey),
                  let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
            
            for dictionary in dataArray {
                guard let entity = NSEntityDescription.entity(forEntityName: ConfigurationKeys.PlayerKey, in: context),
                      let player = NSManagedObject(entity: entity, insertInto: context) as? Player else { return }
                
                guard let playerDictionary = dictionary as? [String: AnyObject],
                      let playerTeam = playerDictionary[ConfigurationKeys.teamKey] as? String,
                      let playerPlayer = playerDictionary[ConfigurationKeys.playerKey] as? String,
                      let playeRating = playerDictionary[ConfigurationKeys.ratingKey] as? Double,
                      let playerLastGame = playerDictionary[ConfigurationKeys.lastGameKey] as? Date,
                      let playerTimesPlaying = playerDictionary[ConfigurationKeys.timesPlayingKey] as? Int16,
                      let playerMyChoice = playerDictionary[ConfigurationKeys.myChoiceKey] as? Bool,
                      let colorDictionary = playerDictionary[ConfigurationKeys.tintColorKey] as? [String: Float] else { return }
                
                let photoData = playerDictionary[ConfigurationKeys.photoDataKey] as? String
                let photo = UIImage(named: photoData!)
                guard let playerPhotoData = photo?.pngData() else { return }
                
                player.team = playerTeam
                player.player = playerPlayer
                player.rating = playeRating
                player.lastGame = playerLastGame
                player.timesPlaying = playerTimesPlaying
                player.myChoice = playerMyChoice
                player.photoData = playerPhotoData
                player.tintColor = getColor(colorDictionary: colorDictionary)
                
                userDefaults.set(true, forKey: ConfigurationKeys.flagKey)
            }
        }
    }
    
    private func getColor(colorDictionary: [String: Float]) -> UIColor {
        guard let red = colorDictionary[ConfigurationKeys.redKey],
              let green = colorDictionary[ConfigurationKeys.greenKey],
              let blue = colorDictionary[ConfigurationKeys.blueKey] else { return UIColor() }
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1.0)
    }
    
    private func updateSegmentedCtrl() {
        let fetchRequest: NSFetchRequest<Player> = Player.fetchRequest()
        guard let playerName = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) else { return }
        fetchRequest.predicate = NSPredicate(format: "player == %@", playerName)
        
        do {
            let results = try context.fetch(fetchRequest)
            guard let playerInit = results.first else { return }
            player = playerInit
            insertDataFrom(selectedPlayer: playerInit)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func viewConfigurations() {
        view.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        
        teamNameLabel.textAlignment = .center
        teamNameLabel.numberOfLines = 0
        playerLabel.textAlignment = .center
        playerLabel.numberOfLines = 0
        
        myChoice.text = "🏅"
        myChoice.font = myChoice.font.withSize(70)
        
        startButton.layer.cornerRadius = 10
        startButton.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        startButton.tintColor = .white
        
        rateButton.layer.cornerRadius = 10
        rateButton.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        rateButton.tintColor = .white
    }
    
    private enum ConfigurationKeys {
        static let PlayerKey = "Player"
        static let flagKey = "dataWasPreloaded"
        static let dataKey = "data"
        static let plistKey = "plist"
        static let teamKey = "team"
        static let playerKey = "player"
        static let ratingKey = "rating"
        static let lastGameKey = "lastGame"
        static let timesPlayingKey = "timesPlaying"
        static let myChoiceKey = "myChoice"
        static let photoDataKey = "photoData"
        static let tintColorKey = "tintColor"
        static let redKey = "red"
        static let greenKey = "green"
        static let blueKey = "blue"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSegmentedCtrl()
        getDataFromFile()
        viewConfigurations()
        first()
    }
}
