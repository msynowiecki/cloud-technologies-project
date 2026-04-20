const express = require("express");
const { Pool } = require("pg");
const Redis = require("ioredis");


const app = express();
const port = 4000;

app.use(express.json());

const instance = process.env.INSTANCE_ID || Math.random().toString(36).substring(2, 8);
let requests = 0;


const pool = new Pool({
    host: process.env.POSTGRES_HOST,
    port: 5432,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    database: process.env.POSTGRES_DB,
});


async function initDB(retries = 20) {
    while (retries > 0) {
        try {
            await pool.query("SELECT 1");

            await pool.query(`
                CREATE TABLE IF NOT EXISTS items (
                                                     id SERIAL PRIMARY KEY,
                                                     name TEXT NOT NULL,
                                                     price NUMERIC NOT NULL
                );
            `);

            console.log("DB ready");
            return;
        } catch (error) {
            console.log("Waiting for DB...");
            await new Promise(r => setTimeout(r, 2000));
            retries--;
        }
    }

    throw new Error("Could not connect to database after several retries");
}


const redis = new Redis({
    host: process.env.REDIS_HOST,
    port: 6379,
});


app.use((request, response, next) => {
    requests++;
    next();
});


app.get("/api/items", async (request, response) => {
    try {
        const result = await pool.query("SELECT * FROM items ORDER BY id ASC");
        response.json({
            instance,
            items: result.rows
        });
    } catch (error) {
        response.status(500).json({ error: "DB error" });
    }
});


app.post("/api/items", async (request, response) => {
    try {
        const { name, price } = request.body;

        const priceNum = Number(price);

        if (!name || isNaN(priceNum)) {
            return response.status(400).json({ error: "Invalid input" });
        }

        const result = await pool.query(
            "INSERT INTO items(name, price) VALUES($1, $2) RETURNING *",
            [name, priceNum]
        );

        await redis.rpush("queue", JSON.stringify(result.rows[0]));

        response.status(201).json({
            status: "added",
            instance,
            item: result.rows[0],
        });
    } catch (error) {
        response.status(500).json({ error: "DB insert error" });
    }
});


app.get("/api/stats", async (request, response) => {
    const cacheKey = "stats";

    try {
        const cached = await redis.get(cacheKey);

        if (cached) {
            response.setHeader("X-Cache", "HIT");
            return response.json(JSON.parse(cached));
        }

        const totalResult = await pool.query("SELECT COUNT(*) FROM items");

        const stats = {
            total: Number(totalResult.rows[0].count),
            instance,
            uptime: process.uptime(),
            requests,
            time: new Date().toISOString(),
        };

        await redis.set(cacheKey, JSON.stringify(stats), "EX", 10);

        response.setHeader("X-Cache", "MISS");
        response.json(stats);
    } catch (error) {
        response.status(500).json({ error: "DB stats error" });
    }
});


app.get("/api/health", async (request, response) => {
    let postgresStatus = "down";
    let redisStatus = "down";

    try {
        await pool.query("SELECT 1");
        postgresStatus = "up";
    } catch {}

    try {
        await redis.ping();
        redisStatus = "up";
    } catch {}

    response.json({
        status: "ok",
        instance,
        uptime: process.uptime(),
        time: new Date().toISOString(),
        postgres: postgresStatus,
        redis: redisStatus,
    });
});


module.exports = app;

if (process.env.WORKER === "true") {
    console.log("Worker started...");

    setInterval(async () => {
        try {
            const task = await redis.lpop("queue");
            if (task) {
                console.log("Processing task:", task);
            }
        } catch (error) {
            console.error("Worker error:", error);
        }
    }, 3000);

} else {
    if (require.main === module) {
        (async () => {
            try {
                await initDB();
                app.listen(port, () => {
                    console.log("Backend running on", port);
                });
            } catch (error) {
                console.error("Failed to initialize database. Exiting...");
                process.exit(1);
            }
        })();
    }
}