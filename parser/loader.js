var path = require('path');
var csv = require(path.join(__dirname, "csv-loader"));
var Barrier = require(path.join(__dirname, "barrier-points"));

module.exports = function(dir, cb){
	
	var dataset = {};
	
	var barrier = new Barrier(5, function() {
		cb({
			getAgency : function () {
				return dataset.agency;
			},
			getCalendars : function () {
				return dataset.calendar;
			},
			getRoutes : function () {
				return dataset.routes;
			},
			getShapes : function () {
				return dataset.shapes;
			},
			getStops : function () {
				return dataset.stops;
			},
			getStopTimes : function () {
				return dataset.stop_times;
			},
			getTrips : function () {
				return dataset.trips;
			}
		});
	});
	
	['agency', 'routes', 'shapes', 'stops', 'trips'].forEach(function(id){
		csv.load(path.join(dir, id+".txt"), function(data) {
			dataset[id] = data;
			barrier.submit();
		});
	});

};






