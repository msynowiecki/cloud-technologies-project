const express = require("express");


const app = express();
const port = 4000;

app.use(express.json());

let items = [];
let requests = 0;
const instance = process.env.INSTANCE_ID || Math.random().toString(36).substring(2, 8);


app.use((request, response, next) => {
    requests++;
    next();
});


app.get("/api/items", (request, response) => {
    response.json(items);
});


app.post("/api/items", (request, response) => {
    const item = request.body;
    const status = "added " + item;

    items.push(item);

    response.json({ status });
});


app.get("/api/stats", (request, response) => {
    const total = items.length;
    const uptime = process.uptime();
    const time = new Date().toISOString();

    response.json({
        total,
        instance,
        uptime,
        requests,
        time
    });
});


app.get("/api/health", (request, response) => {
    const status = "ok";
    const uptime = process.uptime();
    const time = new Date().toISOString();

    response.json({
        status,
        instance,
        uptime,
        time
    });
});


module.exports = app;

if (require.main === module) {
    app.listen(port, () => console.log("Backend running on", port));
}