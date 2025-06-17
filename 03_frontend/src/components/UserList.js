import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, CircularProgress, Button, TextField } from '@mui/material';
import { v4 as uuidv4 } from 'uuid';
import { fetchAuthSession } from 'aws-amplify/auth';

function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const apiUrl = process.env.REACT_APP_API_URL;

  useEffect(() => {
    fetchUsers();
  }, []);

  const getIdToken = async () => {
    const session = await fetchAuthSession();
    return session.tokens?.idToken?.toString();
  };

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const token = await getIdToken();

      const response = await fetch(`${apiUrl}/users`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();
      setUsers(data);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const addUser = async () => {
    const token = await getIdToken();
    const newUserId = uuidv4();
    console.log("API URL:", apiUrl);
console.log("Token:", await getIdToken());

fetch(`${apiUrl}/users`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`, // <- REQUIRED
    'Content-Type': 'application/json',
  }
});

    await fetch(`${apiUrl}/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        id: newUserId,
        name,
      }),
    });

    setName('');
    fetchUsers();
  };

  const deleteUser = async (id) => {
    const token = await getIdToken();

    await fetch(`${apiUrl}/users/${id}`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    fetchUsers();
  };

  return (
    <div>
      <Typography variant="h5">Users</Typography>
      <TextField
        label="New User"
        value={name}
        onChange={(e) => setName(e.target.value)}
        variant="outlined"
        margin="normal"
      />
      <Button
        onClick={addUser}
        variant="contained"
        color="primary"
        disabled={!name.trim()}
      >
        Add User
      </Button>
      {loading ? (
        <CircularProgress />
      ) : (
        users.map(user => (
          <Card key={user.id} style={{ marginBottom: '10px' }}>
            <CardContent>
              <Typography variant="h6">{user.name}</Typography>
              <Button
                onClick={() => deleteUser(user.id)}
                variant="contained"
                color="secondary"
              >
                Delete
              </Button>
            </CardContent>
          </Card>
        ))
      )}
    </div>
  );
}

export default UserList;
