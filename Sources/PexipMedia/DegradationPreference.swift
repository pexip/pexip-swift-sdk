//
// Copyright 2023 Pexip AS
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

/// A strategy on how to approach low bandwidth conditions for video streams.
@frozen
public enum DegradationPreference: Equatable {
    /// Degrades both framerate and resolution.
    case balanced

    /// Degrades resolution while trying to preserve the framerate.
    case maintainFramerate

    /// Degrades framerate while trying to preserve the resolution.
    case maintainResolution

    /// Degrades neither framerate nor resolution.
    case disabled
}
