export const apiGet = (path) =>
    fetch("/api" + path).then(response => response.json());

export const apiPost = (path, data) =>
    fetch("/api" + path, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data)
    }).then(response => response.json());