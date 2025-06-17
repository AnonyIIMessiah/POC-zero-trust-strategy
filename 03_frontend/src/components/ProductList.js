import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, CircularProgress, Button, TextField } from '@mui/material';
import { v4 as uuidv4 } from 'uuid';
import { fetchAuthSession } from 'aws-amplify/auth';

function ProductList() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const apiUrl = process.env.REACT_APP_API_URL;

  useEffect(() => {
    fetchProducts();
  }, []);

  const getIdToken = async () => {
    const session = await fetchAuthSession();
    return session.tokens?.idToken?.toString();
  };

  const fetchProducts = async () => {
    setLoading(true);
    try {
      const token = await getIdToken();
      const response = await fetch(`${apiUrl}/products`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      const data = await response.json();
      setProducts(data);
    } catch (error) {
      console.error('Error fetching products:', error);
    } finally {
      setLoading(false);
    }
  };

  const addProduct = async () => {
    const token = await getIdToken();
    const newProductId = uuidv4();

    await fetch(`${apiUrl}/products`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        id: newProductId,
        name,
      }),
    });

    setName('');
    fetchProducts();
  };

  const deleteProduct = async (id) => {
    const token = await getIdToken();

    await fetch(`${apiUrl}/products/${id}`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    fetchProducts();
  };

  return (
    <div>
      <Typography variant="h5">Products</Typography>
      <TextField
        label="New Product"
        value={name}
        onChange={(e) => setName(e.target.value)}
        variant="outlined"
        margin="normal"
      />
      <Button
        onClick={addProduct}
        variant="contained"
        color="primary"
        disabled={!name.trim()}
      >
        Add Product
      </Button>
      {loading ? (
        <CircularProgress />
      ) : (
        products.map(product => (
          <Card key={product.id} style={{ marginBottom: '10px' }}>
            <CardContent>
              <Typography variant="h6">{product.name}</Typography>
              <Button
                onClick={() => deleteProduct(product.id)}
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

export default ProductList;
