import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, CircularProgress, Button, TextField } from '@mui/material';
import { v4 as uuidv4 } from 'uuid';

function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const apiUrl = process.env.REACT_APP_API_URL
  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = () => {
    fetch(`${apiUrl}/users`)
      .then(response => response.json())
      .then(data => {
        setUsers(data);
        setLoading(false);
      })
      .catch(error => {
        console.log("Error fetching Users");
        setLoading(false);
      });
  };
  
  const addUser = () => {
    // Generate a unique ID using uuid
    const newUserId = uuidv4();

    fetch(`${apiUrl}/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        id: newUserId, 
        name 
      }),
    }).then(fetchUsers);

    // Clear the input field after adding
    setName('');
  };

  const deleteUser = (id) => {
    fetch(`${apiUrl}/users/${id}`, { method: 'DELETE' })
      .then(fetchUsers);
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
