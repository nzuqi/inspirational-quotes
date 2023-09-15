module.exports = app => {
    const subscriptions = require("../controllers/subscription.controller.js");

    var router = require("express").Router();

    // Create a new Subscription
    router.post("/create", subscriptions.create);
    // Retrieve all subscriptions
    router.get("/", subscriptions.findAll);
    // Retrieve a single Subscription with id
    router.get("/:email", subscriptions.findOne);
    // Update a Subscription with id
    // router.put("/:id", subscriptions.update);
    // Delete a Subscription with id
    // router.delete("/:id", subscriptions.delete);
    // Delete all Subscriptions
    router.delete("/", subscriptions.deleteAll);

    app.use('/api/subscriptions', router);
};