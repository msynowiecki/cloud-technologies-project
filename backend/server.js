const express = require("express");

const app = express();
const port = 4000;

app.use(express.json());

let items = [];
const instance = Math.random().toString(36).substring(2, 8);

app.get("/items", (request, response) => {
    response.json(items);
});

app.post("/items", (request, response) => {
    const item = request.body;
    const status = "added " + item

    items.push(item);

    response.json({ status });
});

app.get("/stats", (request, response) => {
    const total = items.length;

    response.json({
        total,
        instance
    });
});

app.listen(port, () => console.log("Backend running on", port));