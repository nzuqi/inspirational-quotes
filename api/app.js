const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
require('dotenv').config({ path: __dirname + '/.env' });
const Common = require("./app/utils/common");

const app = express();

app.use(cors());

// parse requests of content-type - application/json
app.use(bodyParser.json());
// parse requests of content-type - application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: true }));
// use middleware
app.use(Common.middleware.requestValidator);

const db = require("./app/models");
db.mongoose.connect(db.url, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log("Connected to the database.");
}).catch(err => {
    console.log("Cannot connect to the database: ", err);
    process.exit();
});

require("./app/routes/quote.routes")(app);

const startServer = () => {
    const http = require('http');
    const https = require('https');
    const fs = require('fs');

    const PORT = process.env.INSPR_PORT;
    if (process.env.INSPR_ENV === 'prod') {
        const httpsOptions = {
            key: fs.readFileSync(process.env.INSPR_API_PRIV_KEY, 'utf8'),
            cert: fs.readFileSync(process.env.INSPR_API_CERT, 'utf8')
        };
        https.createServer(httpsOptions, app).listen(PORT, () => {
            console.log(`Inspr API is running on port '${PORT}', '${process.env.INSPR_ENV}' environment.`);
        });
        return;
    }
    http.createServer(app).listen(PORT, () => {
        console.log(`Inspr API is running on port '${PORT}', '${process.env.INSPR_ENV}' environment.`);
    });
};

startServer();