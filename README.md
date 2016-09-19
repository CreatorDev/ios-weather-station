![](docs/img.png)

# The WeatherStation iOS application
WeatherStation iOS application is part of a bigger project. Using code from this respository You will
be able to read sensor values from all the sensors connected to your Weather Station.

## Environment for Weather Station project
The complete IoT Environment is built with following components:
* LWM2M cloud server
* Ci40 application which allows usage of clicks in mirkroBUS sockets.
* Contiki based applications build for clicker platform:
*  [Temperature sensor](https://github.com/CreatorKit/temperature-sensor)
* a mobile application to present Weather measurements.

## Mobile application functionality
This mobile application presents data read from sensors in a user friendly way. Main screen of the app consists
of number of tiles on which current measurements are presented. Each tile has an pictogram different
for various sensors, current value, value unit, as well as minimum and maximum measurements within last 24 hours.

By default all tiles are put into one group but user can create new groups of sensors. Tiles
can be moved to specific group using drag abd drop technique. Those groups persists on a device but
are not propagated to the cloud. Renaming and removing groups is possible as well.

## License
Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies.
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the
following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
