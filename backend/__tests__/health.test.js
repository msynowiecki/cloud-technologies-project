const request = require("supertest");
const app = require("../server");


describe("GET /api/health", () => {
    it("should return status ok", async () => {
        const response = await request(app).get("/api/health");

        expect(response.statusCode).toBe(200);
        expect(response.body.status).toBe("ok");
        expect(response.body).toHaveProperty("uptime");
    });
});