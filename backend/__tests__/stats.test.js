const request = require("supertest");
const app = require("../server");


describe("GET /api/stats", () => {
    it("should return stats object", async () => {
        const response = await request(app).get("/api/stats");

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty("total");
        expect(response.body).toHaveProperty("requests");
    });

    it("should increase requests counter", async () => {
        await request(app).get("/api/stats");
        const response = await request(app).get("/api/stats");

        expect(response.body.requests).toBeGreaterThan(0);
    });
});