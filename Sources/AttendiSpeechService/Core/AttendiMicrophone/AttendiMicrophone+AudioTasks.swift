/// Copyright 2023 Attendi Technology B.V.
/// 
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// 
///     http://www.apache.org/licenses/LICENSE-2.0
/// 
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import Foundation

extension AttendiMicrophone {
    /// Register a task (callback) that should do something with the audio when the user stops recording.
    /// Use this to perform custom actions with the available audio.
    /// The newly available audio is passed to the callback as a 16-bit signed integer, 16 KHz WAV-encoded binary
    /// Data blob. A registered audio task needs to be activated by calling ``setActiveAudioTask`` with its ``taskId``.
    ///
    /// - Returns: A function that de-registers the added task.
    @discardableResult
    public func registerAudioTask(taskId: String, task: @escaping (Data) async -> Void) -> (() -> Void) {
        audioTasks[taskId] = task
        
        return {
            removeAudioTask(taskToRemoveId: taskId)
        }
    }
    
    /// The microphone can have multiple registered audio tasks, but only the *active* audio tasks are performed.
    /// Use this function to set a registered audio task to *active*.
    public func setActiveAudioTask(_ taskId: String) {
        // TODO: check if `taskId` exists in registered tasks.
        activeAudioTasks = Set([taskId])
        activeAudioTaskHistory.append(activeAudioTasks)
    }
    
    /// The microphone can have multiple registered audio tasks, but only the *active* audio tasks are performed.
    /// Use this function to set multiple registered audio task to *active*.
    public func setActiveAudioTasks(taskIds: [String]) {
        if activeAudioTasks == Set(taskIds) {
            print("activeAudioTasks is already set to", taskIds)
            return
        }
        
        activeAudioTasks = Set(taskIds)
        activeAudioTaskHistory.append(activeAudioTasks)
    }
    
    /// De-registers an audio task.
    public func removeAudioTask(taskToRemoveId: String) {
        var newAudioTasks: [String: (Data) async -> Void] = [:]
        for (taskId, task) in audioTasks {
            if taskId != taskToRemoveId {
                newAudioTasks[taskId] = task
            }
        }
        
        // TODO: remove the audio task anywhere it's present in the history
        //  not a big deal for now.
        if activeAudioTasks.contains(taskToRemoveId) {
            activeAudioTasks.remove(taskToRemoveId)
            activeAudioTaskHistory.append(activeAudioTasks)
        }
        
        audioTasks = newAudioTasks
    }
    
    /// Plugins can set new audio tasks to active, but they might want to undo their actions. Since they
    /// don't necessarily have knowledge of what the previous active audio task was, they can call this method
    /// instead.
    public func goBackInActiveAudioTaskHistory() {
        _  = activeAudioTaskHistory.popLast()
        if let previousActiveAudioTask = activeAudioTaskHistory.last {
            activeAudioTasks = previousActiveAudioTask
        }
    }
}
