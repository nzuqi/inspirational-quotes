const db = require("../models");
const Quote = db.quotes;
const Common = require('../utils/common');
const fs = require('fs');

// create and save a new Quote
exports.create = async (req, res) => {
    const { quote, author, } = req.body;
    // validate request
    if (!quote || !author) return res.status(400).send({
        status: 2,
        message: "Required fields are missing",
        data: null,
    });

    // create a Quote
    const quoteObj = new Quote({ quote, author, });

    // save Quote in db
    quoteObj.save()
        .then(data => {
            res.status(200).send({
                status: 1,
                message: "Success",
                data,
            });
        }).catch(err => {
            res.status(500).send({
                status: 4,
                message: err.message || "Some error occurred while creating the Quote.",
                data: null
            });
        });
};

// Retrieve all Quotes from the database
exports.findAll = (req, res) => {
    const { query } = req.params;
    let condition = {};
    if (query) {
        const search = { $regex: new RegExp(query), $options: "i" };
        condition = { $or: [{ "author": search }, { "quote": search }] };
    }

    Quote.find(condition)
        .then(data => {
            res.status(200).send({
                status: 1,
                message: "Success",
                data,
            });
        })
        .catch(err => {
            res.status(500).send({
                status: 4,
                message: err.message || "Some error occurred while retreiving quotes.",
                data: null
            });
        });
};

// Find a single Quote with an id
exports.findOne = (req, res) => {
    const { id } = req.params;

    Quote.findById(id)
        .then(data => {
            if (!data) res.status(404).send({
                status: 5,
                message: "No quote found with id: " + id,
                data,
            });
            else res.status(200).send({
                status: 1,
                message: "Success",
                data,
            });
        })
        .catch(err => {
            res.status(500).send({
                status: 4,
                message: "Error retrieving quote with id: " + id,
                data: null
            });
        });
};

// Update a Quote by the id in the request
exports.update = (req, res) => {
    if (!req.body || Common.isObjEmpty(req.body)) {
        return res.status(400).send({
            status: 2,
            message: "Data to update is missing",
            data: null,
        });
    }

    const { id } = req.params;

    Quote.findByIdAndUpdate(id, req.body, { useFindAndModify: false })
        .then(data => {
            if (!data) {
                res.status(404).send({
                    status: 5,
                    message: `Cannot update quote with id: ${id}`,
                    data: null
                });
            } else res.status(200).send({
                status: 1,
                message: "Success",
                data,
            });
        })
        .catch(err => {
            res.status(500).send({
                status: 4,
                message: "Error updating quote with id: " + id,
                data: null
            });
        });
};

// Delete a Quote with the specified id in the request
exports.delete = (req, res) => {
    const { id } = req.params;

    Quote.findByIdAndRemove(id)
        .then(data => {
            if (!data) res.status(404).send({
                status: 5,
                message: `Cannot delete Quote with id: ${id}`,
                data,
            });
            else res.status(200).send({
                status: 1,
                message: "Success",
                data,
            });
        })
        .catch(err => {
            res.status(500).send({
                status: 4,
                message: "Error deleting quote with id: " + id,
                data: null
            });
        });
};

// Delete all Quotes from the database.
exports.deleteAll = (req, res) => {
    Quote.deleteMany({})
        .then(data => {
            res.status(200).send({
                status: 1,
                message: `${data.deletedCount} quotes were deleted successfully`,
                data,
            });
        })
        .catch(err => {
            res.status(500).send({
                status: 4,
                message: err.message || "Some error occurred while removing all quotes.",
                data: null
            });
        });
};

// Seed Quotes from JSON file
exports.seed = (req, res) => {
    fs.readFile(__dirname + '/../../data/inspr_quotes.json', 'utf8', (err, data) => {
        if (err) {
            return res.status(500).send({
                status: 4,
                message: err.message || "Some error occurred while removing all quotes.",
                data: null
            });
        };
        const allQuotes = JSON.parse(data);
        Quote.insertMany(allQuotes)
            .then(data => {
                res.status(200).send({
                    status: 1,
                    message: `${data.length} quotes were seeded successfully`,
                    data,
                });
            })
            .catch(err => {
                res.status(500).send({
                    status: 4,
                    message: err.message || "Some error occurred while seeding quotes.",
                    data: null
                });
            });
    });
};