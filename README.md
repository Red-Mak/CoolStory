# CoolStory

Using SwifUI, CoreData, Async/Await and Combine, i tried to mimic Instagram story UI/UX the best i can in 4 hours :)

## Technical stack

### Architecture

I used MVVM to achive the desired result. MVVM give us the flexibility and the speed to go fast while maintaining and excellent  maintanability and scalability for the future.

* NetworkClient is easely mockable and switch automatically to different configuration for different build envirement (using the static var `auto`), this allow as to mock the data for unit testing or for xCode view preview.

### Used Framework

##### SwiftUI
SwiftUI is the UI framework for all Apple plateforms, by time it is becoming more capable and suitable for almost all new apps. This is why i choose to it exclusevely.

##### CoreData
This is a framework i personaly like and i used it allot, this is why i choosed it instead of SwiftData.

##### Combine
Its the best choise to use MVVM with SwiftUI.

##### Async/Await
This is not a framework :) but its the newest, fastest and safest way to do async calls.

##### KingFisher
Third-party and a well know/maintained package, i used it to download, cache and display images. i could use the SwiftUI built in solution for async fetching images but it lacks cache.

## Known issues

* As we are using the same users list to have an infinite loop in the users list in the `FeedView`, the state of `likedAtLeastOnce` and `storyAlreadySeen` will be the same for all users having the same id.
* I used DropBox to store data (json files and images), sometimes DropBox cut the network connection in simulators, please use real device or delete the app on simulator the reinstall it.
* `ProgressView` is not marked as `finished` (white color)

## What could be enhanced?

* We could customise `ContentUnavailableView` and add a `retry` button inside to restart network request if it fails.
* Add more data in story like the post date.
* Go to next story and/or next user-stories automatically at the end of the progress.
* Use `xcconfig` files to tweak build configuration.
