//
//  ContentDetailModel.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/4/25.
//

import Foundation

struct ContentDetailModel: Codable {
    let contentid: String
    let typeCode: String
    let contenttypeid: String
    let homepage: String?
    let tel: String?
    let telname: String?
    let title: String?
    let firstimage: String?
    let firstimage2: String?
    let address: String?
    let overview: String?
    let parking: String?
    let useseason: String?
    let openInfo: OpenInfo?
    let infocenterculture: String?
    let restdateculture: String?
    let usefee: String?
    let usetimeculture: String?
    let scale: String?
    let spendtime: String?
    let parkingInfo: ParkingInfo?
    let bookingplace: String?
    let discountinfofestival: String?
    let eventplace: String?
    let playtime: String?
    let program: String?
    let spendtimefestival: String?
    let usetimefestival: String?
    let festivalDurationInfo: FestivalDurationInfo?
    let distance: String?
    let infocentertourcourse: String?
    let schedule: String?
    let taketime: String?
    let theme: String?
    let reservation: String?
    let scaleleports: String?
    let usefeeleports: String?
    let leportsOpenInfo: LeportsOpenInfo?
    let leportsParkingInfo: LeportsParkingInfo?
    let parkinglodging: String?
    let reservationurl: String?
    let barbecue: String?
    let bicycle: String?
    let campfire: String?
    let refundregulation: String?
    let checkInOutInfo: CheckInOutInfo?
    let infocentershopping: String?
    let parkingshopping: String?
    let restroom: String?
    let shopguide: String?
    let storeOpenInfo: StoreOpenInfo?
    let packing: String?
    let parkingfood: String?
    let treatmenu: String?
    let foodOpenInfo: FoodOpenInfo?
}

struct OpenInfo: Codable {
    let usetime: String?
    let restdate: String?
}

struct ParkingInfo: Codable {
    let parkingculture: String?
    let parkingfee: String?
}

struct FestivalDurationInfo: Codable {
    let eventstartdate: String?
    let eventenddate: String?
}

struct LeportsOpenInfo: Codable {
    let openperiod: String?
    let restdateleports: String?
    let usetimeleports: String?
}

struct LeportsParkingInfo: Codable {
    let parkingfeeleports: String?
    let parkingleports: String?
}

struct CheckInOutInfo: Codable {
    let checkintime: String?
    let checkouttime: String?
}

struct StoreOpenInfo: Codable {
    let opendateshopping: String?
    let opentime: String?
    let restdateshopping: String?
}

struct FoodOpenInfo: Codable {
    let opendatefood: String?
    let opentimefood: String?
}

extension ContentDetailModel {
    var resolvedTitle: String {
        if let t = title, !t.isEmpty {
            return t
        }
        
        if let overview = overview {
            // overview 문장을 단어 단위로 쪼갬
            let words = overview.split(separator: " ")
            if let firstWord = words.first(where: { $0.hasSuffix("은") || $0.hasSuffix("는") }) {
                // "와룡공원은" → "와룡공원"
                let cleaned = firstWord.dropLast()
                return String(cleaned)
            }
        }
        
        return ""
    }
}
