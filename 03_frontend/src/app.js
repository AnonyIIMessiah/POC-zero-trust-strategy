import React, { useState } from 'react';
import { Container, Grid, CssBaseline, createTheme, ThemeProvider, Switch } from '@mui/material';
import { Amplify } from 'aws-amplify';
import { Authenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

import Navbar from './components/Navbar';
import UserList from './components/UserList';
import ProductList from './components/ProductList';
import Analytics from './components/Analytics';
import awsExports from './aws-exports';

// Configure Amplify with your AWS exports
Amplify.configure(awsExports);

function App() {
  const [darkMode, setDarkMode] = useState(false);

  const theme = createTheme({
    palette: {
      mode: darkMode ? 'dark' : 'light',
    },
  });

  // Authenticator configuration to require email
  const services = {
    async validateCustomSignUp(formData) {
      if (!formData.email) {
        return {
          email: 'Email is required',
        };
      }
      // Add more validation if needed
    },
  };

  const formFields = {
    signUp: {
      email: {
        order: 1,
        isRequired: true,
        label: 'Email Address *',
        placeholder: 'Enter your email address',
      },
      username: {
        order: 2,
        isRequired: true,
        label: 'Username *',
        placeholder: 'Enter your username',
      },
      password: {
        order: 3,
        isRequired: true,
        label: 'Password *',
        placeholder: 'Enter your password',
      },
      confirm_password: {
        order: 4,
        isRequired: true,
        label: 'Confirm Password *',
        placeholder: 'Confirm your password',
      },
    },
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Authenticator
        services={services}
        formFields={formFields}
        signUpAttributes={['email']}
      >
        {({ signOut, user }) => (
          <>
            <Navbar />
            <Container>
              <Switch 
                checked={darkMode} 
                onChange={() => setDarkMode(!darkMode)} 
              />
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
              <button 
                onClick={signOut} 
                style={{ 
                  marginTop: '20px', 
                  padding: '10px 20px', 
                  cursor: 'pointer' 
                }}
              >
                Sign out
              </button>
              {user && (
                <div style={{ marginTop: '10px' }}>
                  <p>Hello, {user.username || user.signInDetails?.loginId}!</p>
                  <p>Email: {user.attributes?.email}</p>
                </div>
              )}
            </Container>
          </>
        )}
      </Authenticator>
    </ThemeProvider>
  );
}

export default App;