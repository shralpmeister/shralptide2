<img src="icon.png" width="100" height="100"/>

ShralpTide2  
-----------
A tide clock and tide predictor for mobile devices.

Introduction
------------

ShralpTide2 provides a reduced feature set of the excellent Unix
command line tide tool, XTide, in a format accessible to the casual
beach goer on the Apple mobile devices including iPhone, iPad and
Apple Watch..

Hardware and operating system requirements
------------------------------------------

ShralpTide2 can be run only on an Apple iOS or Apple Watch devices or simulators. 
An iPhone simulator requires an Intel-based Mac running Mac OS X 10.5
or newer.  It can be obtained free of charge from Apple as part of the 
iPhone SDK at http://developer.apple.com/iphone. Registration is required.

ShralpTide2 can be installed using the iTunes App Store or by using Apple's
iPhone SDK. Using the SDK it is possible to install it on the iPhone 
simulator or on an iPhone provisioned with a Development key.

Usage
-----

Launching ShralpTide2 will bring up a utility style interface with the current
tide level for the selected location displayed at the top and each tide event
for the day displayed at the bottom.

Scroll horizontally in the bottom half of the scrren to show tide events for 
the next few days. Dots at the bottom of the screen show
the number of pages -- the highlighted dot showing the position of the
current page.

Turning the device from a portrait to landscape orientation will display a
plot of the tidal movement for the selected day. If the present day is 
selected a red line or cursor indicates the current time. In the bar at the
top of the screen the tide level and associated time are displayed. Touching 
the screen causes the cursor to jump to the point of contact and the tide
shown at the top of the screen changes to reflect the tide level at the 
point in time nearest the cursor. This works the same for the following days
except that the cursor rests on midnight instead of the current time. New
in ShralpTide2 are sunrise, sunset and moonrise, moonset times. They are
displayed in the header of the landscape plot screen. Daylight hours are
plotted with a blue background and moonlit hours are plotted with a trans-
parent white overlay.

When ShralpTide2 is first launched after installation it calculates tides for
the default tide station at La Jolla, California. To choose the location
nearest you touch the location icon at the bottom left of the portrait mode
display. This feature will ask the iPhone or iTouch for its location and
query the tide stations for those closest to that location. The display will
flip over and display those locations displayed on a map view of the region.

If the device doesn't return a location the globe icon on the bottom right
of the portrait display will allow selection from a list of all the tide
stations in the local database organized by country and state/province. The 
last tide station selected will be remembered as long as ShralpTide2 remains 
installed on the device.

ShralpTide2 adds a settings page under the iOS settings app. There the units
of measure, number of days to show tide predictions for and currents can be
configured. It is also possible to select an alternative background skin from
a handful of predefined choices.

Apple Watch
-----------

If you have paired an Apple Watch with your iPhone, ShralpTide2 will be
installed on the watch automatically.

To see the current tide level on your watch face you must customize the
watch face and select a ShralpTide complication. 

There are tide complications
for just about every watch face and complication style. It's just a matter 
of selecting the one that best suits your preferences.


Installing from source code
---------------------------

To build ShralpTide from source an Intel based machine running Mac OS X 10.5
and the iPhone SDK is required. The iPhone SDK is available as a free download
from Apple's developer web site, http://developer.apple.com/iphone. The SDK
alone will be enough to build and deploy to an iPhone simulator. Additional
steps are needed to deploy on the iPhone itself. See Apple's website and do
some searching on the internet for available deployment options.

Download the source code from Github at 
http://github.com/shralpmeister/shralptide2.

The source is available in both zip and tar.gz formats or you can clone the
git repository with the following command:

    git clone git://github.com/shralpmeister/shralptide2.git

To build and run the project open the project, ShralpTide2.xcodeproj, in XCode.

Select the "Debug - Simulator" build configuration. Click the build and run 
icon in the menu bar. The build will take a little while to finish. When
finished it will launch the Simulator, install ShralpTide, and run it.

Repeat the same steps but with "Debug - Device" to install it on your 
development iPhone.

Acknowlegements
---------------

Thanks to Dave Flater of XTide fame for providing excellent free software
and writing awesome FAQs.

Thanks to all the XTide contributers.

Thanks to my wife Larissa and my children Alexander and Dasha.

Contact Info
------------

Mike Parlee
[shralpmeister@icloud.com](mailto://shralpmeister@icloud.com)
