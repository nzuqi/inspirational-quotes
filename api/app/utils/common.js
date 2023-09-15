
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
            message: "Sorry, you're not authorized to make this request.",
        };
        if (authorization) {
            if (authorization === process.env.INSPR_AUTH) next();
            else return res.status(401).send(errResponse);
        } else {
            return res.status(401).send(errResponse);
        }
    },
};

module.exports = {
    isObjEmpty,
    isInArray,
    middleware,
}