//
//  ColorDataService.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//
import CoreData

@MainActor
class ColorDataService {
    static func saveColorToCoreData(trackID: String, songColor: Int32) {
        let context = ViewModel.shared.coreDataContainer.viewContext
        let fetchRequest: NSFetchRequest<IDToColor> = IDToColor.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", trackID)

        do {
            let colorMapping = try context.fetch(fetchRequest).first ?? IDToColor(context: context)
            colorMapping.id = trackID
            colorMapping.songColor = songColor
            try context.save()
            print("ColorDataService: Successfully saved color \(songColor) for trackID \(trackID)")
        } catch {
            print("ColorDataService: Couldn't save color mapping to CoreData: \(error)")
        }
    }
}
