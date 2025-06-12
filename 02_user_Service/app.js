const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());

// DynamoDB config
const dynamoDb = new AWS.DynamoDB.DocumentClient({ region: 'ap-south-1' });
const USERS_TABLE = 'Users'; // Make sure the table exists


// GET all users
app.get('/users', async (req, res) => {
  try {
    const data = await dynamoDb.scan({ TableName: USERS_TABLE }).promise();
    res.json(data.Items);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch users' });
  }
});

// GET single user
app.get('/users/:id', async (req, res) => {
  const params = {
    TableName: USERS_TABLE,
    Key: { id: req.params.id }
  };

  try {
    const data = await dynamoDb.get(params).promise();
    if (!data.Item) return res.status(404).json({ error: 'User not found' });
    res.json(data.Item);
  } catch (err) {
    res.status(500).json({ error: 'Could not retrieve user' });
  }
});

// POST - Add user
app.post('/users', async (req, res) => {
  const { id, name } = req.body;
  if (!id || !name) return res.status(400).json({ error: 'Missing id or name' });

  const params = {
    TableName: USERS_TABLE,
    Item: { id, name }
  };

  try {
    await dynamoDb.put(params).promise();
    res.status(201).json({ message: 'User added' });
  } catch (err) {
    res.status(500).json({ error: 'Could not add user' });
  }
});

// PUT - Update user
app.put('/users/:id', async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Missing name' });

  const params = {
    TableName: USERS_TABLE,
    Key: { id: req.params.id },
    UpdateExpression: 'SET #n = :name',
    ExpressionAttributeNames: { '#n': 'name' },
    ExpressionAttributeValues: { ':name': name }
  };

  try {
    await dynamoDb.update(params).promise();
    res.json({ message: 'User updated' });
  } catch (err) {
    res.status(500).json({ error: 'Could not update user' });
  }
});

// DELETE - Remove user
app.delete('/users/:id', async (req, res) => {
  const params = {
    TableName: USERS_TABLE,
    Key: { id: req.params.id }
  };

  try {
    await dynamoDb.delete(params).promise();
    res.json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Could not delete user' });
  }
});

// app.get('/', (req, res) => {
//   res.send('Express Lambda is running!');
// });

// Export Lambda handler
module.exports = app;
