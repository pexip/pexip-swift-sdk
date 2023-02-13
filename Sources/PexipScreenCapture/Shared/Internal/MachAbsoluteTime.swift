//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

struct MachAbsoluteTime {
    let value: UInt64

    init(_ value: UInt64) {
        self.value = value
    }

    var nanoseconds: UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return value * UInt64(timebase.numer) / UInt64(timebase.denom)
    }
}
