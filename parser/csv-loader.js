const csv = require('csv-parser');
const fs = require("fs");

module.exports = (function () {

    let load = function (filename, cb) {

        let result = [];
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
