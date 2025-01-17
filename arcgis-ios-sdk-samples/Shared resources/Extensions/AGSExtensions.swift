//
// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import ArcGIS

extension AGSJobStatus {
    func statusString() -> String {
        switch self {
        case .started:
            return "Started"
        case .paused:
            return "Paused"
        case .canceling:
            return "Canceling"
        case .notStarted:
            return "Not started"
        case .succeeded:
            return "Succeeded"
        case .failed:
            return "Failed"
        @unknown default:
            return "Unknown"
        }
    }
}
