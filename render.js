const path = require('path');
const crypto = require('crypto');
const jquery = require('jquery');
const fs = require('fs');
const Gtfs = require(path.join(__dirname, ".", "parser", "loader"));

const argv = require('yargs')
    .usage('Usage: $0 --verbose --gtfs=[path] --poster --max-dist=[num] --center=[lat,lng]')
    .demandOption(['gtfs'])
    .default('max-dist', 20)
    .boolean('v')
    .boolean('poster')
    .alias('v', 'verbose')
    .help('h')
    .alias('h', 'help')
    .describe('v', 'Make verbose')
    .describe('gtfs', 'Path to a gtfs directory')
    .describe('max-dist', 'Maximum distance from the center')
    .describe('center', 'Coordinates of the center')
    .describe('poster', 'Make for an A0 poster size')
    .argv;

let shapes;
let trips;
let segments = [];
let sequences = {};
let max;
let min;
let bbox;
let gtfs;
let render_area = {width: 5000, height: 5000};
let render_area_a0 = {width: 9933, height: 9933};
let center_lat;
let center_lon;
let max_dist = argv['max-dist']; // kilometers

if (argv.size !== undefined) {
    render_area = {width: parseInt(argv.size), height: parseInt(argv.size)};
}

if (argv.center !== undefined) {
    [center_lat, center_lon] = argv.center.split(",");
}

if (argv.poster) {
    render_area = render_area_a0;
}

debug("Running with parameters:\n");
debug(`GTFS provider: ${argv.gtfs}`);
debug(`Render area: ${render_area.width} x ${render_area.height} px`);
debug(`Center coordinates: ${center_lat}, ${center_lon}`);
debug(`Max distance from center: ${max_dist}km`);


let requiredFile = "./gtfs/" + argv.gtfs + "/shapes.txt";
if (!fs.existsSync(requiredFile)) {
    console.error("\nERROR: " + requiredFile + " does not exist.\nExiting.\n");
    process.exit(1);
}

debug("Loading GTFS files...");
Gtfs("./gtfs/" + argv.gtfs + "/", function (data) {
    debug("GTFS files loaded.\n");
    gtfs = data;
    shapes = gtfs.getShapes();
    trips = gtfs.getTrips();

    prepareData();
    createFile();
});

/* possible bug: can there be more route types for one shape? */
let route_types = {};
function getRouteTypeForShapeId(shape_id) {
    let route_type = route_types[shape_id];
    let short_type = (route_type/100)>>0;
    if (short_type == 7) {
        route_type = 3;
    }
    else if (short_type == 1) {
        route_type = 2;
    }
    else if (short_type == 5) {
        route_type = 1;
    }
    else if (short_type == 9 || short_type==8) {
        route_type = 0;
    }
    return route_type;
}

function prepareData() {
    debug("Starting to prepare data...");

    debug("Starting route types iteration...");
    let route_id_types = {};
    gtfs.getRoutes().forEach((route) => {
        route_id_types[route.route_id] = parseInt(route.route_type);
    });
    debug("Finished route type iteration...");
    debug(`Total routes: ${Object.keys(route_id_types).length}`);

    debug("Starting trip iteration...");
    /* count the trips on a certain id */
    let trips_on_a_shape = [];
    trips.forEach((trip) => {
        if (trips_on_a_shape[trip.shape_id] == undefined)
            trips_on_a_shape[trip.shape_id] = 1;
        else
            trips_on_a_shape[trip.shape_id]++;

        let route_type = route_id_types[trip.route_id];
        if (route_types[trip.shape_id] == undefined)
            route_types[trip.shape_id] = route_type;
    });

    // clean
    route_id_types = null;

    debug("Finished trip iteration...");

    /* ensure that the shape points are in the correct order */

    debug("Starting shape iteration...");
    shapes.forEach((shape) => {
        if (sequences[shape.shape_id] == undefined)
            sequences[shape.shape_id] = [];

        // check out of boundaries
        if (center_lat !== undefined && center_lon !== undefined) {
            let distance_from_center = getDistanceFromLatLonInKm(shape.shape_pt_lat, shape.shape_pt_lon, center_lat, center_lon);
            if (distance_from_center <= max_dist) {
                sequences[shape.shape_id][shape.shape_pt_sequence] = shape;
            }
        }
        
    });

    gtfs = null;
    shapes = null;
    trips = null;

    debug("Preparing data finished.");
    debug("\nStarting to create shape segments array with trips per segment...");

    for (var i in sequences) {
        var shape_id = i;
        var route_type = getRouteTypeForShapeId(shape_id);

        if (route_type == undefined) {
            continue;
        }
        if (trips_on_a_shape[shape_id] == undefined) {
            continue
        }

        var tripsN = trips_on_a_shape[shape_id];

        if (tripsN > max || max == undefined)
            max = tripsN;

        if (tripsN < min || min == undefined)
            min = tripsN;

        var pts = [];
        for (var n in sequences[i]) {
            var shape = sequences[i][n];

            adjustBBox([new Number(shape.shape_pt_lat),
                    new Number(shape.shape_pt_lon)]);
            pts.push({'lat': shape.shape_pt_lat, 'lon': shape.shape_pt_lon});
        }
        if (pts.length === 0) {
            continue;
        }
        segments.push({
            "trips": tripsN,
            "coordinates": pts,
            "route_type": route_type
        });
    }
    debug("Segments created.");

    if (max == min && max > 0) min--;
    if (max == min && max <= 0) max++;

    debug("max trips per segment: " + max);
    debug("min trips per segment: " + min);

}

function coord2px(lat, lng) {
    var coordX = bbox.width_f * (lng - bbox.left);
    var coordY = bbox.height_f * (bbox.top - lat);

    return {x: coordX, y: coordY};
}

function adjustBBox(coords) {
    if (coords.length === 0) {
        console.error("no coordinates could be parsed!");
        console.error(JSON.stringify(coords));
        process.exit(1);
    }

    if (!bbox) {
        bbox = {
            left: coords[1]
            , right: coords[1]
            , top: coords[0]
            , bottom: coords[0]
            , width: 0
            , height: 0

            , shift_x: 0
            , shift_y: 0
        };
    }

    if (coords[1] < bbox.left)
        bbox.left = coords[1];

    if (coords[1] > bbox.right)
        bbox.right = coords[1];

    if (coords[0] > bbox.top)
        bbox.top = coords[0];

    if (coords[0] < bbox.bottom)
        bbox.bottom = coords[0];

    bbox.height = bbox.top - bbox.bottom;
    bbox.width = bbox.right - bbox.left;

    bbox.width_f = render_area.width / bbox.width;
    bbox.height_f = render_area.height / bbox.height;

    /* how much do we need to shift for the points to be in the visible area? */
    var top_left = coord2px(bbox.left, bbox.top);
    if (top_left.x < 0)
    // so much, that the outermost point is on 0
        bbox.shift_x = -1 * top_left.x;
    else if (top_left.x > render_area.width)
        bbox.shift_x = -1 * top_left.x;

    if (top_left.y < 0)
        bbox.shift_y = -1 * top_left.y;
    else if (top_left.y > render_area.height)
        bbox.shift_y = -1 * top_left.y;
}

function hash(val) {
    let md5 = crypto.createHash('sha1');
    md5.update(JSON.stringify(val), "ascii");

    return md5.digest("hex")
}

function createFile() {
    fs.writeFileSync("./output/" + argv.gtfs + "/data.lines", "", "utf8");

    var working = 0;
    var segm_length = segments.length;
    debug("\nStarting to create file...");

    for (var i in segments) {
        var segment = segments[i];
        var coords = "";
        for (var un in segment.coordinates) {
            var px = coord2px(segment.coordinates[un].lat, segment.coordinates[un].lon);
            coords += px.x + " " + px.y + ","
        }

        var route_type = segment.route_type;
        var line = segment.trips + "\t" + route_type + "\t" + coords + "\n";
        fs.appendFileSync("./output/" + argv.gtfs + "/data.lines",
            line, "utf8", function (err) {
            if (err) throw err;
        });

        if ((segm_length - working) % 10 == 0)
            debug((segm_length - working) + " left");

        working += 1;
    }

    fs.writeFileSync("./output/" + argv.gtfs + "/maxmin.lines", max + "\n" + min, "utf8");

    debug("Files written.");
}

function debug(msg) {
    if (argv.verbose) {
        let now = (new Date());
        console.log(now.getHours() + "h" + now.getMinutes() + "m: " + msg);
    }
}

function getDistanceFromLatLonInKm(lat1,lon1,lat2,lon2) {
    let R = 6371; // Radius of the earth in km
    let dLat = deg2rad(lat2-lat1);  // deg2rad below
    let dLon = deg2rad(lon2-lon1);
    let a =
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon/2) * Math.sin(dLon/2)
    ;
    let c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    let d = R * c; // Distance in km
    return d;
}

function deg2rad(deg) {
    return deg * (Math.PI/180)
}
