const fs = require('fs');

// check if object is empty
const isObjEmpty = (obj) => {
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) return false;
    }
    return true;
}

const isInArray = (needle, haystack) => {
    var length = haystack.length;
    for (var i = 0; i < length; i++) {
        if (haystack[i] == needle)
            return true;
    }
    return false;
}

const middleware = {
    requestValidator: (req, res, next) => {
        const { authorization } = req.headers;
        const errResponse = {
            status: 3,
            message: "Unauthorized request",
        };
        fs.readFile(__dirname + '/../../.key', 'utf8', (err, data) => {
            if (err) return res.status(401).send(errResponse);

            if (authorization && data) {
                if (authorization.trim() === data.trim()) next();
                else return res.status(401).send(errResponse);
            } else {
                return res.status(401).send(errResponse);
            }
        });
    },
};

module.exports = {
    isObjEmpty,
    isInArray,
    middleware,
}