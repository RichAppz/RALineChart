# RALineChart

RALineChart is a simple, low memory cost, line chart. This was built for Cryp2Watch and other apps in RichAppz.

## Supports

- iOS 12.0+

## Requirements

- Xcode 11.0+
- Swift 4.2+

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Alamofire into your Xcode project using CocoaPods, specify it in your `Podfile`:
 
```ruby
pod 'RALineChart'
```

### Implementation

```swift
import RALineChart
```

Create object in your views and provide dataset

```swift
lazy var view: LineChart = {
    let view = LineChart()
    view.backgroundColor = .clear
    view.isCurved = true
    view.lineColor = .black
    view.isTouchable = true
    view.clipsToBounds = true
    view.touchColor = .black
    view.callback = { [weak self] set in
        guard let set = set else { return }
        self?.setDataset(set)
    }
    view.setupView()
    return view
}()
```

```swift
view.dataSet = [
    Dataset(value: 1, timestamp: 10), 
    Dataset(value: 2, timestamp: 20)
]
```

## Licence (Mit)

Copyright (c) 2017-2021 RichAppz Limited (https://richappz.com)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.


------------

Rich Mucha, RichAppz Limited
rich@richappz.com
