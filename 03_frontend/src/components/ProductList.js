import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, CircularProgress, Button, TextField } from '@mui/material';
import { v4 as uuidv4 } from 'uuid';

function ProductList() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const apiUrl = process.env.REACT_APP_API_URL

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = () => {
    fetch(`${apiUrl}/products`)
      .then(response => response.json())
      .then(data => {
        setProducts(data);
        setLoading(false);
      })
      .catch(error => {
        console.log("Error fetching Products");
        setLoading(false);
      });
  };

  const addProduct = () => {
    // Generate a unique ID using uuid
    const newProductId = uuidv4();

    fetch(`${apiUrl}/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        id: newProductId, 
        name 
      }),
    }).then(fetchProducts);

    // Clear the input field after adding
    setName('');
  };

  const deleteProduct = (id) => {
    // console.log(id);
    
    fetch(`${apiUrl}/products/${id}`, { method: 'DELETE' })
      .then(fetchProducts);
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