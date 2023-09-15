module.exports = mongoose => {
    var schema = mongoose.Schema(
        {
            quote: { type: String, default: '' },
            author: { type: String, default: '' },
        },
        { timestamps: true }
    );

    schema.method("toJSON", function () {
        const { __v, _id, ...object } = this.toObject();
        object.id = _id;
        return object;
    });

    const Quote = mongoose.model("quote", schema);

    return Quote;
};