import React, { useState } from 'react';
import { Container, Grid, CssBaseline, createTheme, ThemeProvider, Switch } from '@mui/material';
import Navbar from './components/Navbar';
import UserList from './components/UserList';
import ProductList from './components/ProductList';
import Analytics from './components/Analytics';

function App() {
  const [darkMode, setDarkMode] = useState(false);

  const theme = createTheme({
    palette: {
      mode: darkMode ? 'dark' : 'light',
    },
  });

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Navbar />
      <Container>
        <Switch checked={darkMode} onChange={() => setDarkMode(!darkMode)} />
        <span>Toggle Dark Mode</span>
        <Grid container spacing={4}>
          <Grid item xs={12} md={6}>
            <UserList />
          </Grid>
          <Grid item xs={12} md={6}>
            <ProductList />
          </Grid>
          <Grid item xs={12}>
            <Analytics />
          </Grid>
        </Grid>
      </Container>
    </ThemeProvider>
  );
}

export default App;
