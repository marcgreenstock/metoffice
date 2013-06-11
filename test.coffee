MetOffice = require('./metoffice.coffee')

metOffice = new MetOffice('d039ddbf-89c9-4189-9fc4-a7370a89a879')
# metOffice.locations (error, locations) ->
#   console.log error if error
#   console.log locations
metOffice.forecast 354693, (error, forecast) ->
  console.log error if error
  console.log forecast
