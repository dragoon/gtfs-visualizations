var csv = require('csv-parser')
var fs = require("fs");

module.exports = (function () {

    var load = function (filename, cb) {

        var result = [];
        fs.createReadStream("./" + filename, {"encoding": "utf8"})
            .pipe(csv())
            .on('data', function (row) {
                result.push(row);
            }).on('end', function () {
                // We are done
                cb(result);
            });
    };

    return {
        load: load
    };
})();
