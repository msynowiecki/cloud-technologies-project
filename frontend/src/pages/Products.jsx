import React, { useEffect, useState } from "react";

import { apiGet, apiPost } from "../api";


export default function Products() {
    const [items, setItems] = useState([]);
    const [name, setName] = useState("");

    const load = () => apiGet("/items").then(setItems);

    useEffect(() => {
        load();
    }, []);

    const add = () => {
        apiPost("/items", { name }).then(() => {
            setName("");
            load();
        });
    };

    return (
        <>
            <h2>Products</h2>
            <input value={name} onChange={e => setName(e.target.value)} />
            <button onClick={add}>Add</button>

            <ul>
                {items.map((i, idx) => <li key={idx}>{i.name}</li>)}
            </ul>
        </>
    );
}