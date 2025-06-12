const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();
const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());

// AWS DynamoDB Setup

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = "Products";

// 📌 GET all product
app.get('/products', async (req, res) => {
    try {
        const data = await dynamoDB.scan({ TableName: TABLE_NAME }).promise();
        res.json(data.Items);
    } catch (err) {
        res.status(500).json({ error: 'Error fetching products' });
    }
});

// 📌 GET a single product
app.get('/products/:id', async (req, res) => {
    try {
        const params = {
            TableName: TABLE_NAME,
            Key: { id: req.params.id }
        };
        const data = await dynamoDB.get(params).promise();
        if (!data.Item) return res.status(404).json({ error: "Product not found" });
        res.json(data.Item);
    } catch (err) {
        res.status(500).json({ error: 'Error fetching product' });
    }
});

// 📌 POST new product
app.post('/products', async (req, res) => {
    const { id, name, price } = req.body;
    if (!id || !name || !price) {
        return res.status(400).json({ error: 'Missing id, name, or price' });
    }

    const params = {
        TableName: TABLE_NAME,
        Item: { id, name, price }
    };

    try {
        await dynamoDB.put(params).promise();
        res.status(201).json({ message: 'Product added' });
    } catch (err) {
        res.status(500).json({ error: 'Error adding product' });
    }
});

// 📌 PUT update product
app.put('/products/:id', async (req, res) => {
    const { name, price } = req.body;
    if (!name || !price) {
        return res.status(400).json({ error: 'Missing name or price' });
    }

    const params = {
        TableName: TABLE_NAME,
        Key: { id: req.params.id },
        UpdateExpression: "set #nm = :n, price = :p",
        ExpressionAttributeNames: { "#nm": "name" },
        ExpressionAttributeValues: { ":n": name, ":p": price },
        ReturnValues: "UPDATED_NEW"
    };

    try {
        const data = await dynamoDB.update(params).promise();
        res.json({ message: "Product updated", updatedAttributes: data.Attributes });
    } catch (err) {
        res.status(500).json({ error: 'Error updating product' });
    }
});

// 📌 DELETE product
app.delete('/products/:id', async (req, res) => {
    const params = {
        TableName: TABLE_NAME,
        Key: { id: req.params.id }
    };

    try {
        await dynamoDB.delete(params).promise();
        res.json({ message: "Product deleted" });
    } catch (err) {
        res.status(500).json({ error: 'Error deleting product' });
    }
});

module.exports = app;
