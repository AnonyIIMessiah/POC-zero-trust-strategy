import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { fetchAuthSession } from 'aws-amplify/auth';

function Analytics() {
  const [userCount, setUserCount] = useState(0);
  const [productCount, setProductCount] = useState(0);
  const apiUrl = process.env.REACT_APP_API_URL;

  useEffect(() => {
    fetchCounts();
  }, []);

  const getIdToken = async () => {
    const session = await fetchAuthSession();
    return session.tokens?.idToken?.toString();
  };

  const fetchCounts = async () => {
    try {
      const token = await getIdToken();

      const [usersRes, productsRes] = await Promise.all([
        fetch(`${apiUrl}/users`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
        fetch(`${apiUrl}/products`, {
          headers: { Authorization: `Bearer ${token}` },
        }),
      ]);

      const usersData = await usersRes.json();
      const productsData = await productsRes.json();

      setUserCount(usersData.length);
      setProductCount(productsData.length);
    } catch (error) {
      console.error('Error fetching analytics data:', error);
    }
  };

  const data = [
    { name: 'Users', count: userCount },
    { name: 'Products', count: productCount },
  ];

  return (
    <div>
      <h2>Analytics</h2>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data}>
          <XAxis dataKey="name" />
          <YAxis allowDecimals={false} />
          <Tooltip />
          <Legend />
          <Bar dataKey="count" fill="#8884d8" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

export default Analytics;
