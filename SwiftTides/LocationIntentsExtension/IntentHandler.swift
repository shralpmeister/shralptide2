//
//  IntentHandler.swift
//  LocationIntentsExtension
//
//  Created by Michael Parlee on 7/5/21.
//

import Intents

class IntentHandler: INExtension, SelectLocationIntentHandling {
    
    let appStateRepo = AppStateRepository()
    let config = ConfigHelper()
    
    func provideLocationOptionsCollection(for intent: SelectLocationIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        appStateRepo.loadSavedState(isLegacy: config.settings.legacyMode)
        let locationStrings:[NSString] = (appStateRepo.favoriteLocations(isLegacy: config.settings.legacyMode).array as! [SDFavoriteLocation]).map { (fav: SDFavoriteLocation) in
            fav.locationName! as NSString
        }
        completion(INObjectCollection(items: locationStrings), nil)
    }
    
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
