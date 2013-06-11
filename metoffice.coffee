http   = require('http')
moment = require('moment')

module.exports = class MetOffice
  @baseUrl: "http://datapoint.metoffice.gov.uk/public/data/val/wxfcs/all/json"

  @weatherTypes:
    NA: "Not available"
    0:  "Clear night"
    1:  "Sunny day"
    2:  "Partly cloudy (night)"
    3:  "Partly cloudy (day)"
    4:  "Not used"
    5:  "Mist"
    6:  "Fog"
    7:  "Cloudy"
    8:  "Overcast"
    9:  "Light rain shower (night)"
    10: "Light rain shower (day)"
    11: "Drizzle"
    12: "Light rain"
    13: "Heavy rain shower (night)"
    14: "Heavy rain shower (day)"
    15: "Heavy rain"
    16: "Sleet shower (night)"
    17: "Sleet shower (day)"
    18: "Sleet"
    19: "Hail shower (night)"
    20: "Hail shower (day)"
    21: "Hail"
    22: "Light snow shower (night)"
    23: "Light snow shower (day)"
    24: "Light snow"
    25: "Heavy snow shower (night)"
    26: "Heavy snow shower (day)"
    27: "Heavy snow"
    28: "Thunder shower (night)"
    29: "Thunder shower (day)"
    30: "Thunder"

  @visibilities:
    UN: "Unknown"
    VP: "Very poor - Less than 1 km"
    PO: "Poor - Between 1-4 km"
    MO: "Moderate - Between 4-10 km"
    GO: "Good - Between 10-20 km"
    VG: "Very good - Between 20-40 km"
    EX: "Excellent - More than 40 km"

  constructor: (@key=null) ->
    throw new Error("metoffice.gov.uk DataPoint API key required.") unless @key
    @

  locations: (cb) ->
    http.get "#{@constructor.baseUrl}/sitelist?key=#{@key}", (res) ->
      data = ''
      res.on 'error', cb
      res.on 'data', (chunk) -> data += chunk.toString()
      res.on 'end', ->
        parseJson data, cb, (json) ->
          if locations = json.Locations?.Location
            cb?(null, locations)
          else
            cb?('locations empty')
    @

  forecast: (locationId, cb) ->
    http.get "#{@constructor.baseUrl}/#{locationId}?key=#{@key}&res=3hourly", (res) ->
      data = ''
      res.on 'error', cb
      res.on 'data', (chunk) -> data += chunk.toString()
      res.on 'end', ->
        parseJson data, cb, (json) ->
          if periods = json.SiteRep?.DV?.Location?.Period
            cb?(null, parsePeriod(periods))
          else
            cb?('forecast empty')
    @

  # Private methods
  parseJson = (json, error, success) ->
    try
      success?(JSON.parse(json))
    catch err
      error?(err)

  parsePeriod = (dayPeriods) ->
    data = []
    for dayPeriod in dayPeriods
      for timePeriod in dayPeriod.Rep
        data.push
          timestamp: do ->
            date = /\d{4}-\d{2}-\d{2}/.exec(dayPeriod.value)[0]
            moment.utc(date).add('minutes', timePeriod.$).format()
          humidity:      parseInt timePeriod.H, 10
          visibility:    timePeriod.V
          uvIndex:       parseInt timePeriod.U, 10
          precipitation: parseInt timePeriod.Pp, 10
          weatherType:   if isNaN(timePeriod.W) then timePeriod.W else parseInt timePeriod.W
          temperature:
            feelsLike:   parseInt timePeriod.F, 10
            actual:      parseInt timePeriod.T, 10
          wind:
            speed:       Math.round(timePeriod.S * 1.61)
            gust:        Math.round(timePeriod.G * 1.61)
            direction:   timePeriod.D
    data
