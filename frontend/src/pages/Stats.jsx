import React, { useEffect, useState } from "react";

import { apiGet } from "../api";


export default function Stats() {
    const [stats, setStats] = useState(null);

    useEffect(() => {
        apiGet("/stats").then(setStats);
    }, []);

    return (
        <>
            <h2>Statistics</h2>

            {stats && (
                <div>
                    <p>Total products: {stats.total}</p>
                    <p>Backend instance ID: {stats.instance}</p>
                    <p>Server uptime: {Math.round(stats.uptime)}s</p>
                    <p>Requests handled: {stats.requests}</p>
                    <p>Server time: {new Date(stats.time).toLocaleString()}</p>
                </div>
            )}
        </>
    );
}