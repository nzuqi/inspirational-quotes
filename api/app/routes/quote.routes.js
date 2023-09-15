module.exports = app => {
    const quotes = require("../controllers/quote.controller.js");

    var router = require("express").Router();

    // Create a new Quote
    router.post("/create", quotes.create);
    // Retrieve all quotes
    router.get("/", quotes.findAll);
    // Retrieve a single Quote with id
    router.get("/:id", quotes.findOne);
    // Update a Quote with id
    router.put("/:id", quotes.update);
    // Delete a Quote with id
    router.delete("/:id", quotes.delete);
    // Delete all quotes
    // router.delete("/", quotes.deleteAll);
    // Seed all quotes from JSON file
    router.post("/seed", quotes.seed);

    app.use('/api/quotes', router);
};